#!/usr/bin/env bash

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
git remote update
if git status -uno | grep -q "Your branch is behind"; then
    echo "⚠️ Your local branch is behind the remote."
    AFFECTED_FILES=$(git diff --name-only HEAD..@{u})
    echo "The following files will be affected by a 'git pull':"
    echo "----------------------------------------------------"
    echo "$AFFECTED_FILES"
    echo "----------------------------------------------------"
    read -p "Do you want to pull these changes before updating? (y/N): " PULL_CHOICE
    if [[ "$PULL_CHOICE" =~ ^[Yy]$ ]]; then
        if echo "$AFFECTED_FILES" | grep -q "flake.lock"; then
            echo "🚨 WARNING: 'flake.lock' is among the remote changes."
            echo "Pulling it may cause a merge conflict with the 'nix flake update' command."
            read -p "Are you sure you want to proceed with the pull? (y/N): " FLAKE_PULL_CHOICE
            if [[ ! "$FLAKE_PULL_CHOICE" =~ ^[Yy]$ ]]; then
                echo "🛑 Pull aborted by user. Continuing update with local configuration."
            else
                 echo "Pulling changes from remote..."
                 git pull
            fi
        else
            echo "Pulling changes from remote..."
            git pull
        fi
    else
        echo "Skipping pull. Continuing update with local configuration."
    fi
else
    echo "✅ Your local configuration is up to date with the remote."
fi

# --- 3. Update Flake Inputs ---
echo "Updating flake inputs..."
if ! sudo nix flake update; then
    echo "❌ 'nix flake update' failed. Aborting."
    exit 1
fi
echo "✅ Flake inputs updated successfully."

# --- 4. Rebuild the System ---
echo "Rebuilding the NixOS system..."
if ! sudo nixos-rebuild switch --flake . --impure; then
    echo "❌ System rebuild failed. The previous configuration is still active. Aborting git commit."
    exit 1
fi
echo "✅ System rebuild successful."

# --- 5. Commit and Push (Only if changes exist) ---
# Check if git status has any output (meaning there are changes)
if [[ -n $(git status --porcelain) ]]; then
    echo "File changes detected. Committing the update..."
    git add .
    git commit -m "update: automatic system update"

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
else
    echo "✅ No file changes to commit. System was already up-to-date."
fi

echo "🎉 NixOS update process complete."
