#!/usr/bin/env bash

# ---- CONFIGURATION ----
MOUNT_PATH="$HOME/OneDrive"   # Adjust as needed
REMOTE_NAME="OneDrive"        # Your rclone remote name

# ---- INPUT FILE ----
FILE_PATH="$1"

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
    notify-send "rclone link" "File not found: $FILE_PATH"
    exit 1
fi

# Ensure the file is within the mount
if [[ "$FILE_PATH" != "$MOUNT_PATH"* ]]; then
    notify-send "rclone link" "File is not under the OneDrive mount"
    exit 1
fi

# Set cursor to 'watch' (busy) — X11 only
xsetroot -cursor_name watch 2>/dev/null

# Get relative path
REL_PATH="${FILE_PATH#$MOUNT_PATH/}"

# Generate rclone link
LINK=$(rclone link "$REMOTE_NAME:$REL_PATH")

# Restore normal cursor
xsetroot -cursor_name left_ptr 2>/dev/null

# Handle failure
if [[ $? -ne 0 || -z "$LINK" ]]; then
    notify-send "rclone link" "Failed to get link"
    exit 1
fi

# Open link
xdg-open "$LINK" &

# Notify user
notify-send "OneDrive link opened" "$LINK"
