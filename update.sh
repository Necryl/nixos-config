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

# --- 1. Variable Defaults & Flag Parsing ---
AUTO_YES=false
# REBUILD_STRATEGY is empty by default, so we know to prompt the user later.
REBUILD_STRATEGY=""

# Use a while loop to handle flags professionally
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)
            AUTO_YES=true
            shift # past argument
            ;;
        --switch)
            REBUILD_STRATEGY="switch"
            shift # past argument
            ;;
        --boot)
            REBUILD_STRATEGY="boot"
            shift # past argument
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ "$AUTO_YES" = true ]; then
    echo -e "${C_GREEN}✅ Running in non-interactive mode.${C_RESET}"
    # If no strategy flag was specified with -y, default to 'boot' for safety.
    if [[ -z "$REBUILD_STRATEGY" ]]; then
        REBUILD_STRATEGY="boot"
    fi
    echo "  - Rebuild strategy set to '${REBUILD_STRATEGY}'."
    echo "  - Other prompts will be auto-accepted."
    echo "--------------------------------------------------------"
fi


# --- 2. Pre-flight Check: Ensure Git Working Directory is Clean ---
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${C_RED}❌ Error: Uncommitted changes detected.${C_RESET}"
    exit 1
fi
echo -e "${C_GREEN}✅ Git working directory is clean.${C_RESET}"

# --- 3. Remote Status Check & Optional Pull ---
# This section's logic is sound and remains unchanged
if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    git remote update &>/dev/null
    if git status -uno | grep -q "Your branch is behind"; then
        echo -e "${C_YELLOW}⚠️ Your local branch is behind the remote.${C_RESET}"
        if [ "$AUTO_YES" = true ] || \
           (read -p "Pull remote changes? (y/N): " pull && [[ "$pull" =~ ^[Yy]$ ]]); then
            echo "Pulling changes..."
            git pull
        fi
    fi
fi

# --- 4. Optional: Update Flake Inputs ---
if [ "$AUTO_YES" = true ] || \
   ! (read -p "Do you want to SKIP the flake update? (y/N): " skip && [[ "$skip" =~ ^[Yy]$ ]]); then
    echo "Updating flake inputs..."
    if ! sudo nix flake update; then
        echo -e "${C_RED}❌ 'nix flake update' failed. Aborting.${C_RESET}"
        exit 1
    fi
else
    echo "Skipping flake update as requested."
fi

# --- 5. Conditional Rebuild ---
if [[ -z $(git status --porcelain) ]]; then
    if [ "$AUTO_YES" = true ] || \
       (read -p "No file changes to apply. Skip the system rebuild? (Y/n): " skip && [[ "$skip" =~ ^[Yy]?$ ]]); then
        echo "Skipping rebuild as requested."
        echo -e "${C_GREEN}🎉 NixOS update process complete.${C_RESET}"
        exit 0
    fi
fi

# --- 6. Choose Rebuild Strategy & Rebuild ---
# If the strategy was not set by a --switch or --boot flag, prompt the user.
if [[ -z "$REBUILD_STRATEGY" ]]; then
    echo -e "${C_BLUE}Please choose the activation strategy:${C_RESET}"
    echo "  1) switch: Immediately activate the new configuration. (Default)"
    echo "  2) boot:   Activate on the next reboot. (Safer for major changes)"
    read -p "Enter choice [1]: " rebuild_choice
    if [[ "$rebuild_choice" == "2" ]]; then
        REBUILD_STRATEGY="boot"
    else
        # This is the default for the interactive prompt if the user just presses Enter.
        REBUILD_STRATEGY="switch"
    fi
fi

echo "Rebuilding the NixOS system with '$REBUILD_STRATEGY' strategy..."
if ! sudo nixos-rebuild "$REBUILD_STRATEGY" --flake . --impure; then
    echo -e "${C_RED}❌ System rebuild failed.${C_RESET}"
    exit 1
fi
echo -e "${C_GREEN}✅ System rebuild successful.${C_RESET}"

# --- 7. Commit and Push ---
if [[ -n $(git status --porcelain) ]]; then
    git add .
    git commit -m "update: automatic system update"

    if [ "$AUTO_YES" = true ] || \
       (read -p "Push update to remote? (y/N): " push && [[ "$push" =~ ^[Yy]$ ]]); then
        echo "Pushing changes to remote..."
        git push
    fi
fi

# --- 8. Final Message ---
echo -e "${C_GREEN}🎉 NixOS update process complete.${C_RESET}"
if [[ "$REBUILD_STRATEGY" == "switch" ]]; then
    echo -e "${C_BLUE}💡 If you encounter issues, you can roll back with: sudo nixos-rebuild switch --rollback${C_RESET}"
elif [[ "$REBUILD_STRATEGY" == "boot" ]]; then
    echo -e "${C_BLUE}💡 The new configuration will be active on your next reboot.${C_RESET}"
fi
