#!/bin/bash

# Configuration
BASE_DIR="/home/opc"
BACKUP_FOLDER="$BASE_DIR/backup-worlds"
LOG_FILE="$BASE_DIR/admin-logs.txt"   # Log file path

# Find and delete backups older than 7 days
OLD_BACKUPS=$(find "$BACKUP_FOLDER" -type d -name "world*" -mtime +7)

# Check if any old backups are found
if [ -n "$OLD_BACKUPS" ]; then
  # Log each deleted backup folder name
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Deleting old backups:" >> "$LOG_FILE"
  for BACKUP in $OLD_BACKUPS; do
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Deleted: $BACKUP" >> "$LOG_FILE"
  done

  # Delete the old backups
  rm -rf $OLD_BACKUPS
  echo "Old backups (older than 7 days) have been deleted from $BACKUP_FOLDER"
else
  echo "No backups older than 7 days found."
fi

