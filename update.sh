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
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'

# --- 1. Sudo Check ---
if [[ "$EUID" -eq 0 ]]; then
    echo -e "${C_YELLOW}⚠️  Warning: Running this script with sudo is not recommended.${C_RESET}"
    echo "This can cause issues with Git authentication (SSH keys) and file permissions."
    echo "The script will attempt to continue, but it may fail."
    echo "--------------------------------------------------------"
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
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ "$AUTO_YES" = true ]; then
    echo -e "${C_GREEN}✅ Running in non-interactive mode.${C_RESET}"
    if [[ -z "$REBUILD_STRATEGY" ]]; then
        REBUILD_STRATEGY="boot"
    fi
    echo "  - Rebuild strategy set to '${REBUILD_STRATEGY}'."
    echo "  - Other prompts will be auto-accepted."
    echo "--------------------------------------------------------"
fi


# --- 3. Pre-flight Check ---
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${C_YELLOW}⚠️  Warning: Uncommitted changes detected.${C_RESET}"
    echo ""
    
    # Show changed files with line counts
    echo -e "${C_BLUE}Changed files:${C_RESET}"
    git diff --stat
    echo ""
    
    # Count total files and lines changed
    FILES_CHANGED=$(git status --porcelain | wc -l)
    LINES_ADDED=$(git diff --numstat | awk '{sum+=$1} END {print sum+0}')
    LINES_REMOVED=$(git diff --numstat | awk '{sum+=$2} END {print sum+0}')
    
    echo -e "${C_BLUE}Summary: ${FILES_CHANGED} file(s) changed, ${LINES_ADDED} insertion(s)(+), ${LINES_REMOVED} deletion(s)(-)${C_RESET}"
    echo ""
    
    if [ "$AUTO_YES" = true ]; then
        echo -e "${C_RED}❌ Error: Cannot proceed with uncommitted changes in non-interactive mode.${C_RESET}"
        exit 1
    fi
    
    read -p "Do you want to commit these changes? (y/N): " commit_choice
    if [[ "$commit_choice" =~ ^[Yy]$ ]]; then
        read -p "Enter commit message: " commit_msg
        if [[ -z "$commit_msg" ]]; then
            echo -e "${C_RED}❌ Error: Commit message cannot be empty.${C_RESET}"
            exit 1
        fi
        git add .
        git commit -m "$commit_msg"
        echo -e "${C_GREEN}✅ Changes committed.${C_RESET}"
    else
        echo -e "${C_RED}❌ Error: Uncommitted changes must be resolved before continuing.${C_RESET}"
        exit 1
    fi
fi
echo -e "${C_GREEN}✅ Git working directory is clean.${C_RESET}"

# --- 4. Remote Status Check ---
if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    git remote update &>/dev/null
    if git status -uno | grep -q "Your branch is behind"; then
        echo -e "${C_YELLOW}⚠️ Your local branch is behind the remote.${C_RESET}"
        if [ "$AUTO_YES" = true ] || \
           (read -p "Pull remote changes? (Y/n): " pull && [[ "$pull" =~ ^[Yy]?$ ]]); then
            echo "Pulling changes..."
            git pull
        fi
    fi
fi

# --- 5. Optional: Update Flake Inputs ---
if [ "$AUTO_YES" = true ] || \
   (read -p "Do you want to SKIP the flake update? (Y/n): " skip && [[ "$skip" =~ ^[Yy]?$ ]]); then
    echo "Skipping flake update as requested."
else
    echo "Updating flake inputs..."
    if ! sudo nix flake update; then
        echo -e "${C_RED}❌ 'nix flake update' failed. Aborting.${C_RESET}"
        exit 1
    fi
fi

# --- 6. Conditional Rebuild ---
if [[ -z $(git status --porcelain) ]]; then
    if [ "$AUTO_YES" = true ] || \
       (read -p "No file changes to apply. Skip the system rebuild? (Y/n): " skip && [[ "$skip" =~ ^[Yy]?$ ]]); then
        echo "Skipping rebuild as requested."
        echo -e "${C_GREEN}🎉 NixOS update process complete.${C_RESET}"
        exit 0
    fi
fi

# --- 7. Choose Rebuild Strategy & Rebuild ---
if [[ -z "$REBUILD_STRATEGY" ]]; then
    echo -e "${C_BLUE}Please choose the activation strategy:${C_RESET}"
    echo "  1) switch: Immediately activate the new configuration."
    echo "  2) boot:   Activate on the next reboot. (Safer - Default)"
    read -p "Enter choice [2]: " rebuild_choice
    if [[ "$rebuild_choice" == "1" ]]; then
        REBUILD_STRATEGY="switch"
    else
        REBUILD_STRATEGY="boot"
    fi
fi

echo "Rebuilding the NixOS system with '$REBUILD_STRATEGY' strategy..."
if ! sudo nixos-rebuild "$REBUILD_STRATEGY" --flake . --impure; then
    echo -e "${C_RED}❌ System rebuild failed.${C_RESET}"
    exit 1
fi
echo -e "${C_GREEN}✅ System rebuild successful.${C_RESET}"

# --- 8. Commit and Push ---
if [[ -n $(git status --porcelain) ]]; then
    git add .
    git commit -m "update: automatic system update"

    if [ "$AUTO_YES" = true ] || \
       (read -p "Push update to remote? (Y/n): " push && [[ "$push" =~ ^[Yy]?$ ]]); then
        echo "Pushing changes to remote..."
        git push
    fi
fi

# --- 9. Final Message ---
echo -e "${C_GREEN}🎉 NixOS update process complete.${C_RESET}"
if [[ "$REBUILD_STRATEGY" == "switch" ]]; then
    echo -e "${C_BLUE}💡 If you encounter issues, you can roll back with: sudo nixos-rebuild switch --rollback${C_RESET}"
elif [[ "$REBUILD_STRATEGY" == "boot" ]]; then
    echo -e "${C_BLUE}💡 The new configuration will be active on your next reboot.${C_RESET}"
fi
