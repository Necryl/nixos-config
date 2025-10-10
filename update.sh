#!/usr/bin/env bash

# This script automates the NixOS update process.
# Usage:
#   bash update.sh      - Run in interactive mode.
#   bash update.sh -y   - Run in non-interactive mode with special behaviors.

# --- Strict Mode ---
# set -e: exit immediately if a command exits with a non-zero status.
# set -u: treat unset variables as an error when substituting.
# set -o pipefail: the return value of a pipeline is the status of the last command to exit with a non-zero status.
set -euo pipefail

# --- Color Definitions ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'

# --- 1. Parse Command-Line Flags ---
AUTO_YES=false
if [[ "${1:-}" == "-y" ]]; then # Use ${1:-} to avoid error with set -u
    AUTO_YES=true
    echo -e "${C_GREEN}✅ Running in non-interactive mode (-y flag detected).${C_RESET}"
    echo "This means:"
    echo "  - Remote changes will be pulled automatically."
    echo "  - The flake update will be SKIPPED automatically."
    echo "  - The system rebuild will be skipped automatically if no other changes are found."
    echo "  - Successful updates will be pushed to the remote repository automatically."
    echo "--------------------------------------------------------"
fi

# --- 2. Pre-flight Check: Ensure Git Working Directory is Clean ---
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${C_RED}❌ Error: Uncommitted changes detected in your Nix configuration.${C_RESET}"
    echo "Please commit or stash your changes before running the update."
    exit 1
fi
echo -e "${C_GREEN}✅ Git working directory is clean.${C_RESET}"

# --- 3. Remote Status Check & Optional Pull ---
# Check if an upstream branch is configured
if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    echo "Checking for remote updates..."
    git remote update &>/dev/null
    if git status -uno | grep -q "Your branch is behind"; then
        echo -e "${C_YELLOW}⚠️ Your local branch is behind the remote.${C_RESET}"
        
        PULL_CHOICE="n"
        if [ "$AUTO_YES" = true ]; then
            echo "'-y' flag detected. Automatically pulling remote changes."
            PULL_CHOICE="y"
        else
            read -p "Do you want to pull remote changes before updating? (y/N): " user_pull_choice
            if [[ "$user_pull_choice" =~ ^[Yy]$ ]]; then PULL_CHOICE="y"; fi
        fi

        if [[ "$PULL_CHOICE" == "y" ]]; then
            # ... (rest of the pull logic is unchanged)
            AFFECTED_FILES=$(git diff --name-only HEAD..@{u})
            if echo "$AFFECTED_FILES" | grep -q "flake.lock"; then
                FLAKE_PULL_CHOICE="n"
                if [ "$AUTO_YES" = true ]; then FLAKE_PULL_CHOICE="y"; else
                    echo -e "${C_YELLOW}🚨 WARNING: 'flake.lock' is among the remote changes, which may conflict with the update.${C_RESET}"
                    read -p "Are you sure you want to proceed with the pull? (y/N): " user_flake_pull_choice
                    if [[ "$user_flake_pull_choice" =~ ^[Yy]$ ]]; then FLAKE_PULL_CHOICE="y"; fi
                fi
                if [[ "$FLAKE_PULL_CHOICE" == "n" ]]; then
                    echo -e "${C_RED}🛑 Pull aborted by user. Continuing update with local configuration.${C_RESET}"
                    PULL_CHOICE="n"
                fi
            fi
            if [[ "$PULL_CHOICE" == "y" ]]; then
                echo "Pulling changes from remote..."
                git pull
            fi
        else
            echo "Skipping pull. Continuing update with local configuration."
        fi
    else
        echo -e "${C_GREEN}✅ Your local configuration is up to date with the remote.${C_RESET}"
    fi
else
    echo -e "${C_YELLOW}ℹ️ No remote upstream branch configured. Skipping remote check.${C_RESET}"
fi


# --- 4. Optional: Update Flake Inputs ---
SKIP_FLAKE_UPDATE="n"
if [ "$AUTO_YES" = true ]; then
    echo "'-y' flag detected. Automatically SKIPPING flake update."
    SKIP_FLAKE_UPDATE="y"
else
    read -p "Do you want to SKIP the flake update? (y/N): " user_skip_choice
    if [[ "$user_skip_choice" =~ ^[Yy]$ ]]; then SKIP_FLAKE_UPDATE="y"; fi
fi

if [[ "$SKIP_FLAKE_UPDATE" == "n" ]]; then
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
    if [[ "$SKIP_FLAKE_UPDATE" == "n" ]]; then
        echo -e "${C_BLUE}💡 No updates found for flake inputs. Your system configuration is unchanged.${C_RESET}"
    fi
    
    SKIP_REBUILD="n"
    if [ "$AUTO_YES" = true ]; then
        echo "'-y' flag detected. Automatically skipping rebuild."
        SKIP_REBUILD="y"
    else
        read -p "Do you want to skip the system rebuild? (Y/n): " skip_rebuild_choice
        if [[ "$skip_rebuild_choice" =~ ^[Yy]?$ ]]; then SKIP_REBUILD="y"; fi
    fi

    if [[ "$SKIP_REBUILD" == "y" ]]; then
        echo "Skipping rebuild as requested. No changes to apply."
        echo -e "${C_GREEN}🎉 NixOS update process complete.${C_RESET}"
        exit 0
    fi
fi

# --- 6. Rebuild the System ---
echo "Rebuilding the NixOS system..."
if ! sudo nixos-rebuild switch --flake . --impure; then
    echo -e "${C_RED}❌ System rebuild failed. The previous configuration is still active.${C_RESET}"
    exit 1
fi
echo -e "${C_GREEN}✅ System rebuild successful.${C_RESET}"

# --- 7. Commit and Push (Only if changes exist) ---
if [[ -n $(git status --porcelain) ]]; then
    echo "File changes detected. Committing the update..."
    git add .
    git commit -m "update: automatic system update"

    PUSH_CHOICE="n"
    if [ "$AUTO_YES" = true ]; then
        echo "'-y' flag detected. Automatically pushing to remote."
        PUSH_CHOICE="y"
    else
        read -p "Push update to remote? (y/N): " user_push_choice
        if [[ "$user_push_choice" =~ ^[Yy]$ ]]; then PUSH_CHOICE="y"; fi
    fi

    if [[ "$PUSH_CHOICE" == "y" ]]; then
        echo "Pushing changes to remote..."
        if git push; then
            echo -e "${C_GREEN}✅ Pushed successfully.${C_RESET}"
        else
            echo -e "${C_RED}❌ Git push failed.${C_RESET}"
            exit 1
        fi
    else
        echo "Skipping push. The update is committed locally."
    fi
else
    echo -e "${C_GREEN}✅ No file changes to commit.${C_RESET}"
fi

echo -e "${C_GREEN}🎉 NixOS update process complete.${C_RESET}"
echo -e "${C_BLUE}💡 If you encounter issues with the new generation, you can roll back with: sudo nixos-rebuild switch --rollback${C_RESET}"
