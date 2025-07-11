#!/bin/bash

# Configuration
MOUNT_POINT="/home/necryl/OneDrive"
REMOTE="OneDrive:"
CONFIG_FILE="/home/necryl/.config/rclone/rclone.conf"
LOG_FILE="/home/necryl/rclone-toggle.log"
RCLONE_BIN="/run/current-system/sw/bin/rclone"
FUSERMOUNT_BIN="/run/wrappers/bin/fusermount3"
FINDMNT_BIN="/run/current-system/sw/bin/findmnt"

# Ensure mount point exists
mkdir -p "$MOUNT_POINT" || {
    echo "$(date): ERROR: Failed to create mount point $MOUNT_POINT" >> "$LOG_FILE"
    notify-send "ERROR: Failed to create mount point $MOUNT_POINT"
    exit 1
}

# Function to check if OneDrive is mounted
is_mounted() {
    "$FINDMNT_BIN" "$MOUNT_POINT" >/dev/null 2>&1 && return 0
    # Additional check: non-empty directory might indicate a stale mount
    [ -n "$(ls -A "$MOUNT_POINT" 2>/dev/null)" ] && return 0
    return 1
}

# Recursive function to check mount status
check_mount_recursive() {
    local attempt=$1
    local max_attempts=10
    if is_mounted; then
        echo "$(date): Successfully mounted OneDrive" >> "$LOG_FILE"
        notify-send "OneDrive mounted at $MOUNT_POINT"
        return 0
    fi
    if [ "$attempt" -ge "$max_attempts" ]; then
        echo "$(date): ERROR: Failed to mount OneDrive after $max_attempts attempts" >> "$LOG_FILE"
        notify-send "Failed to mount OneDrive. Check $LOG_FILE for details."
        return 1
    fi
    sleep 0.5 # Short delay to avoid CPU thrashing
    check_mount_recursive $((attempt + 1))
}

# Function to mount OneDrive
mount_onedrive() {
    echo "$(date): Mounting OneDrive at $MOUNT_POINT" >> "$LOG_FILE"
    notify-send "Mounting OneDrive at $MOUNT_POINT"
    "$RCLONE_BIN" mount "$REMOTE" "$MOUNT_POINT" \
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
    local rclone_pid=$!
    if ! check_mount_recursive 1; then
        kill "$rclone_pid" 2>/dev/null
        exit 1
    fi
}

# Function to unmount OneDrive
unmount_onedrive() {
    echo "$(date): Unmounting OneDrive from $MOUNT_POINT" >> "$LOG_FILE"
    notify-send "Unmounting OneDrive from $MOUNT_POINT"
    local rclone_pid=$(pgrep -f "rclone mount $REMOTE $MOUNT_POINT")
    if [ -n "$rclone_pid" ]; then
        kill "$rclone_pid" 2>/dev/null
        sleep 1
    fi
    "$FUSERMOUNT_BIN" -u "$MOUNT_POINT" 2>/dev/null || {
        umount -l "$MOUNT_POINT" 2>/dev/null
        "$FUSERMOUNT_BIN" -u "$MOUNT_POINT" 2>/dev/null
    }
    if ! is_mounted; then
        echo "$(date): Successfully unmounted OneDrive" >> "$LOG_FILE"
        notify-send "OneDrive unmounted from $MOUNT_POINT"
    else
        echo "$(date): ERROR: Failed to unmount OneDrive" >> "$LOG_FILE"
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
