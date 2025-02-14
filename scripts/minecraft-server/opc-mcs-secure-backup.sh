#!/bin/bash

# Configuration
REMOTE_BASE_FOLDER="/home/opc/backup-worlds"
LOCAL_DIR="/mnt/d/DATA/opc-server-backups"

# Find the latest world folder on the remote server
LATEST_WORLD=$(ssh mcs "ls -d $REMOTE_BASE_FOLDER/world* 2>/dev/null | sort -r | head -n 1")

# Check if a valid folder was found
if [ -z "$LATEST_WORLD" ]; then
    echo "No valid world backup found in $REMOTE_BASE_FOLDER on the remote server"
    exit 1
fi

# Step 1: SCP the latest world folder from the remote machine
scp -r mcs:"$LATEST_WORLD" "$LOCAL_DIR"

LATEST_WORLD_NAME=$(basename "$LATEST_WORLD")
if [ -d "$LOCAL_DIR/$LATEST_WORLD_NAME" ]; then
    echo "Backup successful: $LATEST_WORLD_NAME copied to $LOCAL_DIR"
else
    echo "Backup failed: world folder not found"
    exit 1
fi
