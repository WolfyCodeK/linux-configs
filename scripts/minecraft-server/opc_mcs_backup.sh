#!/bin/bash

# Configuration
REMOTE_FOLDER="/home/opc/world"
LOCAL_DIR="/mnt/d/DATA/opc-server-backups"

# Date and time format for folder renaming
TIMESTAMP=$(date +"%m%d%Y-%H%M")

# Step 1: SCP the world folder from the remote machine
scp -r mcs:"$REMOTE_FOLDER" "$LOCAL_DIR"

# Step 2: Rename the folder with the timestamp
if [ -d "$LOCAL_DIR/world" ]; then
    mv "$LOCAL_DIR/world" "$LOCAL_DIR/world$TIMESTAMP"
    echo "Backup successful: world renamed to world$TIMESTAMP"
else
    echo "Backup failed: world folder not found"
    exit 1
fi
