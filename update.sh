#!/usr/bin/env bash

# This script automates the NixOS update process for a configuration managed in a Git repository.
# It checks for local and remote changes, updates flake inputs, rebuilds the system,
# and commits/pushes the changes.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 1. Pre-flight Check: Ensure Git Working Directory is Clean ---
if [[ -n $(git status --porcelain) ]]; then
    echo "Error: Uncommitted changes detected in your Nix configuration."
    echo "Please commit or stash your changes before running the update."
    exit 1
fi
echo "✅ Git working directory is clean."

# --- 2. Remote Status Check & Optional Pull ---
echo "Checking for remote updates..."
# Fetches the latest state from all remotes without merging
git remote update

# Check if the local branch is behind its upstream counterpart
if git status -uno | grep -q "Your branch is behind"; then
    echo "⚠️ Your local branch is behind the remote."
    
    # List files that would be changed by a pull
    AFFECTED_FILES=$(git diff --name-only HEAD..@{u})
    echo "The following files will be affected by a 'git pull':"
    echo "----------------------------------------------------"
    echo "$AFFECTED_FILES"
    echo "----------------------------------------------------"

    read -p "Do you want to pull these changes before updating? (y/N): " PULL_CHOICE
    if [[ "$PULL_CHOICE" =~ ^[Yy]$ ]]; then
        # Specific warning if flake.lock is about to be pulled
        if echo "$AFFECTED_FILES" | grep -q "flake.lock"; then
            echo "🚨 WARNING: 'flake.lock' is among the remote changes."
            echo "Pulling it may cause a merge conflict with the 'nix flake update' command."
            read -p "Are you sure you want to proceed with the pull? (y/N): " FLAKE_PULL_CHOICE
            if [[ ! "$FLAKE_PULL_CHOICE" =~ ^[Yy]$ ]]; then
                echo "🛑 Pull aborted by user. Continuing update with local configuration."
            else
                 echo "Pulling changes from remote..."
                 git pull
                 echo "Log: Files updated from remote:"
                 echo "$AFFECTED_FILES"
            fi
        else
            echo "Pulling changes from remote..."
            git pull
            echo "Log: Files updated from remote:"
            echo "$AFFECTED_FILES"
        fi
    else
        echo "Skipping pull. Continuing update with local configuration."
    fi
else
    echo "✅ Your local configuration is up to date with the remote."
fi


# --- 3. Update Flake Inputs ---
echo "Updating flake inputs..."
if sudo nix flake update; then
    echo "✅ Flake inputs updated successfully."
else
    echo "❌ 'nix flake update' failed. Aborting."
    exit 1
fi

# --- 4. Rebuild the System ---
echo "Rebuilding the NixOS system..."
if sudo nixos-rebuild switch --flake . --impure; then
    echo "✅ System rebuild successful."
else
    echo "❌ System rebuild failed. The previous configuration is still active. Aborting git commit."
    exit 1
fi

# --- 5. Commit the Update ---
echo "Committing the successful update..."
git add .
git commit -m "update"

# --- 6. Optional Push to Remote ---
read -p "Push update to remote? (y/N): " PUSH_CHOICE
if [[ "$PUSH_CHOICE" =~ ^[Yy]$ ]]; then
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

echo "🎉 NixOS update process complete."
