#!/usr/bin/env bash

# This script automates the NixOS update process.
# Usage:
#   bash update.sh [FLAGS]
#
# Flags:
#   -y, --yes      Run in non-interactive mode.
#   --switch       Use the 'switch' rebuild strategy.
#   --boot         Use the 'boot' rebuild strategy.

# --- Strict Mode ---
set -euo pipefail

# --- Color Definitions ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;36m'
C_MAGENTA='\033[0;35m'
C_BOLD='\033[1m'
C_DIM='\033[2m'

# --- Helper Functions ---
print_header() {
    echo ""
    echo -e "${C_BOLD}${C_MAGENTA}▸ $1${C_RESET}"
}

print_success() {
    echo -e "${C_GREEN}✓${C_RESET} $1"
}

print_error() {
    echo -e "${C_RED}✗${C_RESET} $1"
}

print_warning() {
    echo -e "${C_YELLOW}⚠${C_RESET} $1"
}

print_info() {
    echo -e "${C_BLUE}ℹ${C_RESET} $1"
}

prompt() {
    local question="$1"
    local default="$2"
    local response
    
    if [[ "$default" == "y" ]]; then
        echo -ne "${C_BOLD}${C_BLUE}?${C_RESET} ${question} ${C_DIM}(Y/n)${C_RESET} "
    else
        echo -ne "${C_BOLD}${C_BLUE}?${C_RESET} ${question} ${C_DIM}(y/N)${C_RESET} "
    fi
    
    read -r response
    
    if [[ -z "$response" ]]; then
        [[ "$default" == "y" ]] && return 0 || return 1
    elif [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# --- Banner ---
echo ""
echo -e "${C_BOLD}${C_MAGENTA}╔═════════════════════════╗${C_RESET}"
echo -e "${C_BOLD}${C_MAGENTA}║   NixOS Update Script   ║${C_RESET}"
echo -e "${C_BOLD}${C_MAGENTA}╚═════════════════════════╝${C_RESET}"

# --- 1. Sudo Check ---
if [[ "$EUID" -eq 0 ]]; then
    echo ""
    print_warning "Running this script with sudo is not recommended."
    echo -e "  ${C_DIM}This can cause issues with Git authentication (SSH keys)${C_RESET}"
    echo -e "  ${C_DIM}and file permissions. The script will continue, but may fail.${C_RESET}"
fi

# --- 2. Variable Defaults & Flag Parsing ---
AUTO_YES=false
REBUILD_STRATEGY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        --switch)
            REBUILD_STRATEGY="switch"
            shift
            ;;
        --boot)
            REBUILD_STRATEGY="boot"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ "$AUTO_YES" = true ]; then
    echo ""
    print_info "Running in non-interactive mode"
    if [[ -z "$REBUILD_STRATEGY" ]]; then
        REBUILD_STRATEGY="boot"
    fi
    echo -e "  ${C_DIM}→ Rebuild strategy: ${REBUILD_STRATEGY}${C_RESET}"
    echo -e "  ${C_DIM}→ Prompts will be auto-accepted${C_RESET}"
fi

# --- 3. Pre-flight Check ---
print_header "Checking repository status"

if [[ -n $(git status --porcelain) ]]; then
    print_warning "Uncommitted changes detected"
    echo ""
    
    # Show changed files with line counts
    echo -e "${C_DIM}┌─ Changed files:${C_RESET}"
    git diff --stat | sed 's/^/│ /'
    echo -e "${C_DIM}└─${C_RESET}"
    echo ""
    
    # Count total files and lines changed
    FILES_CHANGED=$(git status --porcelain | wc -l)
    LINES_ADDED=$(git diff --numstat | awk '{sum+=$1} END {print sum+0}')
    LINES_REMOVED=$(git diff --numstat | awk '{sum+=$2} END {print sum+0}')
    
    echo -e "  ${C_DIM}${FILES_CHANGED} file(s) • ${C_GREEN}+${LINES_ADDED}${C_RESET}${C_DIM} • ${C_RED}-${LINES_REMOVED}${C_RESET}"
    echo ""
    
    if [ "$AUTO_YES" = true ]; then
        print_error "Cannot proceed with uncommitted changes in non-interactive mode"
        exit 1
    fi
    
    if prompt "Commit these changes now?" "n"; then
        echo -ne "${C_BOLD}${C_BLUE}?${C_RESET} Commit message: "
        read -r commit_msg
        if [[ -z "$commit_msg" ]]; then
            print_error "Commit message cannot be empty"
            exit 1
        fi
        git add .
        git commit -m "$commit_msg"
        print_success "Changes committed"
    else
        print_warning "Continuing with uncommitted changes"
        echo -e "  ${C_DIM}→ Flake update will be skipped to avoid mixing changes${C_RESET}"
    fi
else
    print_success "Git working directory is clean"
fi

# Track if we have uncommitted changes to skip flake update
HAS_UNCOMMITTED=$(git status --porcelain)

# --- 4. Remote Status Check ---
print_header "Checking remote repository"

if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    git remote update &>/dev/null
    if git status -uno | grep -q "Your branch is behind"; then
        print_warning "Local branch is behind remote"
        
        if [ "$AUTO_YES" = true ] || prompt "Pull remote changes?" "n"; then
            echo -e "  ${C_DIM}Pulling changes...${C_RESET}"
            git pull
            print_success "Remote changes pulled"
        else
            print_info "Skipped pulling remote changes"
        fi
    else
        print_success "Local branch is up to date"
    fi
else
    print_info "No remote tracking branch configured"
fi

# --- 5. Optional: Update Flake Inputs ---
print_header "Flake inputs update"

FLAKE_WAS_UPDATED=false

# Skip flake update if there are uncommitted changes
if [[ -n "$HAS_UNCOMMITTED" ]]; then
    print_info "Flake update skipped (uncommitted changes present)"
else
    if [ "$AUTO_YES" = true ]; then
        print_info "Flake update skipped (auto-yes mode defaults to safe option)"
    else
        if prompt "Update flake inputs?" "n"; then
            echo -e "  ${C_DIM}Updating flake inputs...${C_RESET}"
            if ! sudo nix flake update; then
                print_error "'nix flake update' failed"
                exit 1
            fi
            
            # Check if flake.lock actually changed
            if [[ -n $(git status --porcelain flake.lock) ]]; then
                print_success "Flake inputs updated"
                
                # Commit flake.lock immediately after update
                echo -e "  ${C_DIM}Committing flake.lock...${C_RESET}"
                git add flake.lock
                git commit -m "update: flake inputs updated"
                print_success "Flake changes committed"
                FLAKE_WAS_UPDATED=true
            else
                print_success "Flake inputs already up to date"
            fi
        else
            print_info "Flake update skipped by user"
        fi
    fi
fi

# --- 6. Conditional Rebuild ---
CURRENT_GIT_STATE=$(git status --porcelain)
SYSTEM_WAS_REBUILT=false

if [[ -z "$CURRENT_GIT_STATE" ]] && [ "$FLAKE_WAS_UPDATED" = false ]; then
    print_header "System rebuild"
    
    if [ "$AUTO_YES" = true ] || prompt "No changes detected. Skip rebuild?" "y"; then
        print_info "System rebuild skipped (no changes)"
        echo ""
        echo -e "${C_BOLD}${C_BLUE}ℹ${C_RESET} No changes found. System not rebuilt.${C_RESET}"
        echo ""
        exit 0
    fi
fi

# --- 7. Choose Rebuild Strategy & Rebuild ---
print_header "System rebuild"

if [[ -z "$REBUILD_STRATEGY" ]]; then
    echo ""
    echo -e "${C_BOLD}Select activation strategy:${C_RESET}"
    echo -e "  ${C_DIM}1)${C_RESET} switch ${C_DIM}→ Activate immediately${C_RESET}"
    echo -e "  ${C_DIM}2)${C_RESET} boot   ${C_DIM}→ Activate on next reboot (safer, default)${C_RESET}"
    echo ""
    echo -ne "${C_BOLD}${C_BLUE}?${C_RESET} Enter choice ${C_DIM}[2]${C_RESET} "
    read -r rebuild_choice
    if [[ "$rebuild_choice" == "1" ]]; then
        REBUILD_STRATEGY="switch"
    else
        REBUILD_STRATEGY="boot"
    fi
fi

echo -e "  ${C_DIM}Building with strategy: ${REBUILD_STRATEGY}${C_RESET}"
if ! sudo nixos-rebuild "$REBUILD_STRATEGY" --flake . --impure; then
    print_error "System rebuild failed"
    exit 1
fi
print_success "System rebuild successful"
SYSTEM_WAS_REBUILT=true

# --- 8. Commit and Push Logic ---
print_header "Finalizing changes"

# Only prompt to push if flake was updated and committed
if [ "$FLAKE_WAS_UPDATED" = true ]; then
    if [ "$AUTO_YES" = true ] || prompt "Push changes to remote?" "n"; then
        echo -e "  ${C_DIM}Pushing to remote...${C_RESET}"
        git push
        print_success "Changes pushed to remote"
    else
        print_info "Skipped pushing to remote"
    fi
elif [[ -n $(git status --porcelain) ]]; then
    echo ""
    print_warning "You have uncommitted changes:"
    echo ""
    echo -e "${C_DIM}┌─ Status:${C_RESET}"
    git status --short | sed 's/^/│ /'
    echo -e "${C_DIM}└─${C_RESET}"
    echo ""
fi

# --- 9. Final Message ---
echo ""
if [ "$SYSTEM_WAS_REBUILT" = true ]; then
    echo -e "${C_BOLD}${C_GREEN}✓ NixOS update process complete${C_RESET}"
    echo ""
    
    if [[ "$REBUILD_STRATEGY" == "switch" ]]; then
        echo -e "${C_DIM}💡 Rollback: ${C_RESET}sudo nixos-rebuild switch --rollback"
    elif [[ "$REBUILD_STRATEGY" == "boot" ]]; then
        echo -e "${C_DIM}💡 New configuration will be active on next reboot${C_RESET}"
    fi
else
    echo -e "${C_BOLD}${C_BLUE}ℹ${C_RESET} No changes made. System not rebuilt.${C_RESET}"
fi
echo ""
