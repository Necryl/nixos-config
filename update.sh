#!/usr/bin/env bash

# This script automates the NixOS update process.
# Usage:
#   bash update.sh [FLAGS]
#
# Flags:
#   -y, --yes          Run in non-interactive mode.
#   -v, --verbose      Show detailed state snapshot information.
#   --switch           Use the 'switch' rebuild strategy.
#   --boot             Use the 'boot' rebuild strategy.
#   --update-flake     Update flake inputs (works with --yes).
#   --force-rebuild    Force rebuild even if no changes detected.

# --- Strict Mode ---
set -euo pipefail

# --- Constants ---
STATE_FILE=".nixos-rebuild-state"

# --- Trap Setup for Graceful Exit ---
REBUILD_IN_PROGRESS=false
REBUILD_COMPLETED=false

cleanup_on_interrupt() {
    echo ""
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}⚠ Update process interrupted by user${C_RESET}"
    
    if [ "$REBUILD_IN_PROGRESS" = true ]; then
        echo -e "  ${C_DIM}→ System rebuild was in progress - system may be in an inconsistent state${C_RESET}"
        echo -e "  ${C_DIM}→ Consider running the script again or checking system status${C_RESET}"
    elif [ "$REBUILD_COMPLETED" = true ]; then
        echo -e "  ${C_DIM}→ System rebuild completed successfully before interruption${C_RESET}"
        echo -e "  ${C_DIM}→ System changes were applied${C_RESET}"
    else
        echo -e "  ${C_DIM}→ No system changes were made${C_RESET}"
    fi
    
    echo ""
    exit 130
}

trap cleanup_on_interrupt SIGINT SIGTERM

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
    
    read -r -e response
    
    if [[ -z "$response" ]]; then
        [[ "$default" == "y" ]] && return 0 || return 1
    elif [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# --- State Snapshot Functions ---
get_config_state() {
    # Generate a snapshot of all configuration files and their hashes
    # Includes ALL files in the directory (tracked, untracked, and ignored)
    # This ensures files like local-hardware.nix are captured even if in .gitignore
    local all_files
    if ! all_files=$(find . -type f -not -path './.git/*' -not -name "$STATE_FILE" 2>&1 | sort); then
        print_error "Failed to list files: $all_files"
        return 1
    fi
    
    if [[ -z "$all_files" ]]; then
        print_error "No files found in repository"
        return 1
    fi
    
    # Use relative paths and hash them
    echo "$all_files" | xargs sha256sum 2>/dev/null || {
        print_error "Failed to generate file hashes"
        return 1
    }
}

check_config_changed() {
    # Returns 0 (true) if config has changed, 1 (false) if unchanged
    local current_state
    if ! current_state=$(get_config_state); then
        print_error "Failed to get current configuration state"
        return 0  # Assume changed if we can't determine state
    fi
    
    if [[ ! -f "$STATE_FILE" ]]; then
        if [ "$VERBOSE" = true ]; then
            print_info "No previous state file found - treating as changed"
        fi
        return 0
    fi
    
    local previous_state
    previous_state=$(cat "$STATE_FILE")
    
    if [[ "$current_state" != "$previous_state" ]]; then
        if [ "$VERBOSE" = true ]; then
            echo ""
            echo -e "${C_DIM}┌─ Configuration changes:${C_RESET}"
            diff <(echo "$previous_state") <(echo "$current_state") | grep "^[<>]" | head -20 | sed 's/^/│ /'
            local change_count=$(diff <(echo "$previous_state") <(echo "$current_state") | grep "^[<>]" | wc -l)
            if [[ $change_count -gt 20 ]]; then
                echo -e "${C_DIM}│ ... and $((change_count - 20)) more changes${C_RESET}"
            fi
            echo -e "${C_DIM}└─${C_RESET}"
        fi
        return 0
    else
        return 1
    fi
}

update_state_file() {
    # Update the state file with the current configuration snapshot
    if ! get_config_state > "$STATE_FILE"; then
        print_error "Failed to update state file"
        return 1
    fi
    return 0
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
VERBOSE=false
UPDATE_FLAKE=false
FORCE_REBUILD=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
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
        --update-flake)
            UPDATE_FLAKE=true
            shift
            ;;
        --force-rebuild)
            FORCE_REBUILD=true
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
    if [ "$UPDATE_FLAKE" = true ]; then
        echo -e "  ${C_DIM}→ Flake inputs will be updated${C_RESET}"
    fi
fi

if [ "$FORCE_REBUILD" = true ]; then
    echo ""
    print_info "Force rebuild enabled - change detection will be bypassed"
fi

# --- 3. Check Configuration State ---
print_header "Checking configuration state"

CONFIG_CHANGED=false
if [ "$FORCE_REBUILD" = true ]; then
    CONFIG_CHANGED=true
    print_info "Force rebuild enabled - skipping change detection"
elif check_config_changed; then
    CONFIG_CHANGED=true
    print_info "Configuration changes detected"
else
    print_success "Configuration unchanged since last build"
fi

# --- 4. Pre-flight Check ---
print_header "Checking repository status"

HAS_UNCOMMITTED=false
if [[ -n $(git status --porcelain) ]]; then
    HAS_UNCOMMITTED=true
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
    
    # Custom prompt that accepts commit message on the same line
    echo -ne "${C_BOLD}${C_BLUE}?${C_RESET} Commit these changes? ${C_DIM}(y/N or type commit message)${C_RESET} "
    read -e -r commit_response
    
    if [[ -z "$commit_response" ]] || [[ "$commit_response" =~ ^[Nn]$ ]]; then
        print_warning "Continuing with uncommitted changes"
    elif [[ "$commit_response" =~ ^[Yy]$ ]]; then
        # User just typed 'y', ask for message separately
        echo -ne "${C_BOLD}${C_BLUE}?${C_RESET} Commit message: "
        read -e -r commit_msg
        if [[ -z "$commit_msg" ]]; then
            print_error "Commit message cannot be empty"
            exit 1
        fi
        git add .
        git commit -m "$commit_msg"
        print_success "Changes committed"
        HAS_UNCOMMITTED=false
    else
        # User typed a commit message directly
        git add .
        git commit -m "$commit_response"
        print_success "Changes committed"
        HAS_UNCOMMITTED=false
    fi
else
    print_success "Git working directory is clean"
fi

# --- 5. Remote Status Check ---
print_header "Checking remote repository"

HAS_UPSTREAM=false
if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    HAS_UPSTREAM=true
    git remote update &>/dev/null
    if git status -uno | grep -q "Your branch is behind"; then
        print_warning "Local branch is behind remote"
        
        if [ "$AUTO_YES" = true ] || prompt "Pull remote changes?" "n"; then
            echo -e "  ${C_DIM}Pulling changes...${C_RESET}"
            git pull
            print_success "Remote changes pulled"
            # Recheck configuration state after pull
            if [ "$FORCE_REBUILD" = false ] && check_config_changed; then
                CONFIG_CHANGED=true
            fi
        else
            print_info "Skipped pulling remote changes"
        fi
    else
        print_success "Local branch is up to date"
    fi
else
    print_info "No remote tracking branch configured"
fi

# --- 6. Optional: Update Flake Inputs ---
print_header "Flake inputs update"

if [ "$UPDATE_FLAKE" = true ]; then
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
        HAS_UNCOMMITTED=false
        
        # Recheck configuration state after flake update
        if [ "$FORCE_REBUILD" = false ] && check_config_changed; then
            CONFIG_CHANGED=true
        fi
    else
        print_success "Flake inputs already up to date"
    fi
elif [ "$AUTO_YES" = true ]; then
    print_info "Flake update skipped (use --update-flake to enable in auto-yes mode)"
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
            HAS_UNCOMMITTED=false
            
            # Recheck configuration state after flake update
            if [ "$FORCE_REBUILD" = false ] && check_config_changed; then
                CONFIG_CHANGED=true
            fi
        else
            print_success "Flake inputs already up to date"
        fi
    else
        print_info "Flake update skipped by user"
    fi
fi

# --- 7. Conditional Rebuild ---
if [ "$CONFIG_CHANGED" = false ]; then
    print_header "System rebuild"
    
    if [ "$AUTO_YES" = true ] || prompt "No configuration changes detected. Skip rebuild?" "y"; then
        print_info "System rebuild skipped (no changes detected)"
        
        # Show repository status even when skipping
        echo ""
        if [ "$HAS_UNCOMMITTED" = true ]; then
            print_warning "You have uncommitted changes"
        fi
        
        if [ "$HAS_UPSTREAM" = true ]; then
            if git log @{u}.. --oneline 2>/dev/null | grep -q .; then
                print_warning "You have unpushed commits"
            fi
        fi
        
        echo ""
        echo -e "${C_BOLD}${C_BLUE}ℹ${C_RESET} No configuration changes. System not rebuilt.${C_RESET}"
        echo ""
        exit 0
    fi
fi

# --- 8. Choose Rebuild Strategy & Rebuild ---
print_header "System rebuild"

if [[ -z "$REBUILD_STRATEGY" ]]; then
    echo ""
    echo -e "${C_BOLD}Select activation strategy:${C_RESET}"
    echo -e "  ${C_DIM}1)${C_RESET} switch ${C_DIM}→ Activate immediately${C_RESET}"
    echo -e "  ${C_DIM}2)${C_RESET} boot   ${C_DIM}→ Activate on next reboot (safer, default)${C_RESET}"
    echo ""
    echo -ne "${C_BOLD}${C_BLUE}?${C_RESET} Enter choice ${C_DIM}[2]${C_RESET} "
    read -e -r rebuild_choice
    if [[ "$rebuild_choice" == "1" ]]; then
        REBUILD_STRATEGY="switch"
    else
        REBUILD_STRATEGY="boot"
    fi
fi

echo -e "  ${C_DIM}Building with strategy: ${REBUILD_STRATEGY}${C_RESET}"

# Mark that rebuild is starting
REBUILD_IN_PROGRESS=true

if ! sudo nixos-rebuild "$REBUILD_STRATEGY" --flake . --impure; then
    print_error "System rebuild failed"
    REBUILD_IN_PROGRESS=false
    exit 1
fi

REBUILD_IN_PROGRESS=false
REBUILD_COMPLETED=true
print_success "System rebuild successful"

# Update state file after successful rebuild
update_state_file
print_info "Configuration state snapshot updated"

# --- 9. Push Logic ---
print_header "Finalizing changes"

# Only check for unpushed commits if upstream exists
if [ "$HAS_UPSTREAM" = true ]; then
    if git log @{u}.. --oneline 2>/dev/null | grep -q .; then
        if [ "$AUTO_YES" = true ] || prompt "Push changes to remote?" "n"; then
            echo -e "  ${C_DIM}Pushing to remote...${C_RESET}"
            git push
            print_success "Changes pushed to remote"
        else
            print_info "Skipped pushing to remote"
        fi
    fi
fi

# Show uncommitted changes warning if any exist
if [ "$HAS_UNCOMMITTED" = true ]; then
    echo ""
    print_warning "You have uncommitted changes:"
    echo ""
    echo -e "${C_DIM}┌─ Status:${C_RESET}"
    git status --short | sed 's/^/│ /'
    echo -e "${C_DIM}└─${C_RESET}"
    echo ""
fi

# --- 10. Final Message ---
echo ""
echo -e "${C_BOLD}${C_GREEN}✓ NixOS update process complete${C_RESET}"
echo ""

if [[ "$REBUILD_STRATEGY" == "switch" ]]; then
    echo -e "${C_DIM}💡 Rollback: ${C_RESET}sudo nixos-rebuild switch --rollback"
elif [[ "$REBUILD_STRATEGY" == "boot" ]]; then
    echo -e "${C_DIM}💡 New configuration will be active on next reboot${C_RESET}"
fi
echo ""
