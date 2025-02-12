#!/bin/bash

# Configuration
BASE_DIR="."               # Base directory where the world folder is located
BACKUP_FOLDER="backup-worlds"   # Backup folder path
RESTORED_FOLDER="$BASE_DIR/restored-worlds"  # Folder to store old worlds
WORLD_FOLDER="$BASE_DIR/world"    # The active world folder
LOG_FILE="admin-logs.txt"   # Log file path

# Check if the backup name is provided
if [ -z "$1" ]; then
  echo "Usage: ./restore.sh <backup_name>"
  exit 1
fi

BACKUP_NAME="$1"
BACKUP_PATH="$BACKUP_FOLDER/$BACKUP_NAME"

# Ensure the restored-worlds folder exists
mkdir -p "$RESTORED_FOLDER"

# Check if the backup exists
if [ ! -d "$BACKUP_PATH" ]; then
  echo "Backup '$BACKUP_NAME' not found in $BACKUP_FOLDER."
  exit 1
fi

# Generate timestamp for renaming the old world
TIMESTAMP=$(date +"%d%m%Y-%H%M")
RESTORED_WORLD_NAME="world$TIMESTAMP"

# Step 1: Move the current world to the restored-worlds folder with a timestamped name
if [ -d "$WORLD_FOLDER" ]; then
  mv "$WORLD_FOLDER" "$RESTORED_FOLDER/$RESTORED_WORLD_NAME"
  echo "Current world moved to $RESTORED_FOLDER/$RESTORED_WORLD_NAME"
  # Log the world being moved
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Moved current world to: $RESTORED_FOLDER/$RESTORED_WORLD_NAME" >> "$LOG_FILE"
fi

# Step 2: Copy the selected backup and rename it to 'world'
cp -r "$BACKUP_PATH" "$WORLD_FOLDER"

# Step 3: Confirm success
if [ $? -eq 0 ]; then
  echo "Backup '$BACKUP_NAME' restored successfully as 'world'!"
  # Log the backup restoration
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Restored backup: $BACKUP_NAME as 'world'" >> "$LOG_FILE"
else
  echo "Restoration failed. Attempting to restore the original world..."
  mv "$RESTORED_FOLDER/$RESTORED_WORLD_NAME" "$WORLD_FOLDER"
  exit 1
fi


