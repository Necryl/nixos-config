#!/bin/bash

# Configuration
MOUNT_POINT="/home/necryl/OneDrive"
REMOTE="OneDrive:"
CONFIG_FILE="/home/necryl/.config/rclone/rclone.conf"
LOG_FILE="/home/necryl/rclone-toggle.log"
RCLONE_BIN="/run/current-system/sw/bin/rclone"
FUSERMOUNT_BIN="/run/wrappers/bin/fusermount3"

# Ensure mount point exists
mkdir -p "$MOUNT_POINT" || {
    notify-send "$(date): ERROR: Failed to create mount point $MOUNT_POINT" >> "$LOG_FILE"
    exit 1
}

# Function to check if OneDrive is mounted
is_mounted() {
    mountpoint -q "$MOUNT_POINT" || {
        # Additional check: if directory is not empty, it might be a stale mount
        [ -n "$(ls -A "$MOUNT_POINT")" ] && return 0
        return 1
    }
}

# Function to mount OneDrive
mount_onedrive() {
    notify-send "Mounting OneDrive at $MOUNT_POINT" >> "$LOG_FILE"
    $RCLONE_BIN mount "$REMOTE" "$MOUNT_POINT" \
        --vfs-cache-mode full \
        --vfs-read-chunk-size 32M \
        --vfs-cache-max-size 1G \
        --vfs-cache-max-age 48h \
        --buffer-size 32M \
        --dir-cache-time 48h \
        --poll-interval 30s \
        --attr-timeout 1s \
        --config "$CONFIG_FILE" \
        --log-level INFO \
        --log-file "$LOG_FILE" &
    sleep 2 # Wait for mount to initialize
    if is_mounted; then
        notify-send "Successfully mounted OneDrive" >> "$LOG_FILE"
        notify-send "OneDrive mounted at $MOUNT_POINT"
    else
        notify-send "ERROR: Failed to mount OneDrive" >> "$LOG_FILE"
        notify-send "Failed to mount OneDrive. Check $LOG_FILE for details."
        exit 1
    fi
}

# Function to unmount OneDrive
unmount_onedrive() {
    notify-send "Unmounting OneDrive from $MOUNT_POINT" >> "$LOG_FILE"
    # Stop any rclone mount process
    RCLONE_PID=$(pgrep -f "rclone mount $REMOTE $MOUNT_POINT")
    if [ -n "$RCLONE_PID" ]; then
        kill "$RCLONE_PID" 2>/dev/null
        sleep 1
    fi
    # Unmount
    $FUSERMOUNT_BIN -u "$MOUNT_POINT" 2>/dev/null || {
        # Fallback: lazy unmount
        umount -l "$MOUNT_POINT" 2>/dev/null
        $FUSERMOUNT_BIN -u "$MOUNT_POINT" 2>/dev/null
    }
    if ! is_mounted; then
        notify-send "Successfully unmounted OneDrive" >> "$LOG_FILE"
        notify-send "OneDrive unmounted from $MOUNT_POINT"
    else
        notify-send "ERROR: Failed to unmount OneDrive" >> "$LOG_FILE"
        notify-send "Failed to unmount OneDrive. Check $LOG_FILE for details."
        exit 1
    fi
}

# Toggle logic
if is_mounted; then
    unmount_onedrive
else
    mount_onedrive
fi
