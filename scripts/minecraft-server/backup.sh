#!/bin/bash

# Configuration
BASE_DIR="/home/opc"
SOURCE_FOLDER="$BASE_DIR/world"
BACKUP_FOLDER="$BASE_DIR/backup-worlds"
LOG_FILE="$BASE_DIR/admin-logs.txt"   # Log file path

# Date and time format for backup name and timestamp
TIMESTAMP=$(date +"%d%m%Y-%H%M")
BACKUP_NAME="world${TIMESTAMP}"

# Create the backup
cp -r "$SOURCE_FOLDER" "$BACKUP_FOLDER/$BACKUP_NAME"

# Check if the backup was successful
if [ $? -eq 0 ]; then
  # Log the backup creation time and path to the log file
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Backup created: $BACKUP_FOLDER/$BACKUP_NAME" >> "$LOG_FILE"
  echo "Backup created at $BACKUP_FOLDER/$BACKUP_NAME"
else
  # Log the failure if the backup failed
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Backup failed" >> "$LOG_FILE"
  echo "Backup failed"
fi

