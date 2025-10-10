#!/usr/bin/env bash

# This script automates the NixOS update process.
# Usage:
#   bash update.sh      - Run in interactive mode.
#   bash update.sh -y   - Run in non-interactive mode with special behaviors.

set -e

# --- 1. Parse Command-Line Flags ---
AUTO_YES=false
if [[ "$1" == "-y" ]]; then
    AUTO_YES=true
    echo "✅ Running in non-interactive mode (-y flag detected)."
    echo "This means:"
    echo "  - Remote changes will be pulled automatically."
    echo "  - The flake update will be SKIPPED automatically."
    echo "  - The system rebuild will be skipped automatically if no other changes are found."
    echo "  - Successful updates will be pushed to the remote repository automatically."
    echo "--------------------------------------------------------"
fi

# --- 2. Pre-flight Check: Ensure Git Working Directory is Clean ---
if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Error: Uncommitted changes detected in your Nix configuration."
    echo "Please commit or stash your changes before running the update."
    exit 1
fi
echo "✅ Git working directory is clean."

# --- 3. Remote Status Check & Optional Pull ---
echo "Checking for remote updates..."
git remote update &>/dev/null
if git status -uno | grep -q "Your branch is behind"; then
    echo "⚠️ Your local branch is behind the remote."
    
    PULL_CHOICE="n"
    if [ "$AUTO_YES" = true ]; then
        echo "'-y' flag detected. Automatically pulling remote changes."
        PULL_CHOICE="y"
    else
        read -p "Do you want to pull remote changes before updating? (y/N): " user_pull_choice
        if [[ "$user_pull_choice" =~ ^[Yy]$ ]]; then PULL_CHOICE="y"; fi
    fi

    if [[ "$PULL_CHOICE" == "y" ]]; then
        AFFECTED_FILES=$(git diff --name-only HEAD..@{u})
        # Special warning for flake.lock
        if echo "$AFFECTED_FILES" | grep -q "flake.lock"; then
            FLAKE_PULL_CHOICE="n"
            if [ "$AUTO_YES" = true ]; then
                FLAKE_PULL_CHOICE="y"
            else
                echo "🚨 WARNING: 'flake.lock' is among the remote changes, which may conflict with the update."
                read -p "Are you sure you want to proceed with the pull? (y/N): " user_flake_pull_choice
                if [[ "$user_flake_pull_choice" =~ ^[Yy]$ ]]; then FLAKE_PULL_CHOICE="y"; fi
            fi
            
            if [[ "$FLAKE_PULL_CHOICE" == "n" ]]; then
                echo "🛑 Pull aborted by user. Continuing update with local configuration."
                PULL_CHOICE="n" # Prevent pull from happening
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
    echo "✅ Your local configuration is up to date with the remote."
fi

# --- 4. Optional: Update Flake Inputs ---
SKIP_FLAKE_UPDATE="n" # Default action is to NOT skip the update.
if [ "$AUTO_YES" = true ]; then
    echo "'-y' flag detected. Automatically SKIPPING flake update."
    SKIP_FLAKE_UPDATE="y" # With -y, we now skip this step.
else
    # Ask the user if they want to skip. Default is NO.
    read -p "Do you want to SKIP the flake update? (y/N): " user_skip_choice
    if [[ "$user_skip_choice" =~ ^[Yy]$ ]]; then
        SKIP_FLAKE_UPDATE="y"
    fi
fi

if [[ "$SKIP_FLAKE_UPDATE" == "n" ]]; then
    echo "Updating flake inputs..."
    if ! sudo nix flake update; then
        echo "❌ 'nix flake update' failed. Aborting."
        exit 1
    fi
else
    echo "Skipping flake update as requested."
fi

# --- 5. Conditional Rebuild ---
# Check if the update resulted in any file changes
if [[ -z $(git status --porcelain) ]]; then
    echo "💡 No updates found for flake inputs. Your system configuration is unchanged."
    
    SKIP_REBUILD="n"
    if [ "$AUTO_YES" = true ]; then
        echo "'-y' flag detected. Automatically skipping rebuild."
        SKIP_REBUILD="y"
    else
        read -p "Do you want to skip the system rebuild? (Y/n): " skip_rebuild_choice
        # Default to Yes if user presses Enter
        if [[ "$skip_rebuild_choice" =~ ^[Yy]?$ ]]; then SKIP_REBUILD="y"; fi
    fi

    if [[ "$SKIP_REBUILD" == "y" ]]; then
        echo "Skipping rebuild as requested. No changes to apply."
        echo "🎉 NixOS update process complete."
        exit 0
    fi
fi

# --- 6. Rebuild the System ---
echo "Rebuilding the NixOS system..."
if ! sudo nixos-rebuild switch --flake . --impure; then
    echo "❌ System rebuild failed. The previous configuration is still active."
    exit 1
fi
echo "✅ System rebuild successful."

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
            echo "✅ Pushed successfully."
        else
            echo "❌ Git push failed."
            exit 1
        fi
    else
        echo "Skipping push. The update is committed locally."
    fi
else
    echo "✅ No file changes to commit. System was already up-to-date."
fi

echo "🎉 NixOS update process complete."
