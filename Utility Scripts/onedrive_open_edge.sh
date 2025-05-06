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
echo "Link: $REMOTE_NAME:$REL_PATH";
LINK=$(rclone link "$REMOTE_NAME:$REL_PATH")
echo "Recieved: $LINK";
# Restore normal cursor
xsetroot -cursor_name left_ptr 2>/dev/null



# Open link
flatpak run com.microsoft.Edge "$LINK" &

# Notify user
notify-send "OneDrive link opened" "$LINK"
