#!/bin/bash

# Debug mode (set to 1 to enable debugging)
DEBUG=1

# Remote server details - using SSH config alias 'mcs'
REMOTE_HOST="mcs"
REMOTE_DIR="/home/opc/backup-worlds"

# Local destination directory
LOCAL_DIR="/mnt/d/DATA/opc-server-backups"

# Function to print debug messages
debug_echo() {
    if [ "$DEBUG" -eq 1 ]; then
        echo "[DEBUG] $1"
    fi
}

debug_echo "Script started"

# Make sure local destination directory exists
mkdir -p "$LOCAL_DIR"
debug_echo "Local destination directory: $LOCAL_DIR"

# Connect to remote server and find the latest backup
echo "Connecting to remote server $REMOTE_HOST to find latest backup..."

# Find the latest backup on the remote server using SSH
latest_backup=$(ssh $REMOTE_HOST "
    if [ ! -d '${REMOTE_DIR}' ]; then
        echo 'ERROR: Directory ${REMOTE_DIR} does not exist on remote server!'
        exit 1
    fi

    # Function to find latest backup by date parsing
    find_latest() {
        latest_timestamp=0
        latest_name=''
        
        # List all world directories and process them
        for backup in '${REMOTE_DIR}'/world*; do
            if [ -d \"\$backup\" ]; then
                filename=\$(basename \"\$backup\")
                if [[ \$filename =~ world([0-9]{2})([0-9]{2})([0-9]{4})-([0-9]{2})([0-9]{2}) ]]; then
                    day=\"\${BASH_REMATCH[1]}\"
                    month=\"\${BASH_REMATCH[2]}\"
                    year=\"\${BASH_REMATCH[3]}\"
                    hour=\"\${BASH_REMATCH[4]}\"
                    minute=\"\${BASH_REMATCH[5]}\"
                    
                    # Convert to timestamp for comparison (YYYYMMDDHHMMSS)
                    timestamp=\"\${year}\${month}\${day}\${hour}\${minute}\"
                    
                    if [ \"\$timestamp\" -gt \"\$latest_timestamp\" ]; then
                        latest_timestamp=\"\$timestamp\"
                        latest_name=\"\$filename\"
                    fi
                fi
            fi
        done
        
        if [ -z \"\$latest_name\" ]; then
            echo 'ERROR: No valid backup found on remote server!'
            exit 1
        fi
        
        echo \"\$latest_name\"
    }
    
    # Run the function
    find_latest
")

# Check for errors in the SSH command
if [ $? -ne 0 ]; then
    echo "Failed to connect to remote server or find backups!"
    echo "$latest_backup"  # Display the error message from SSH
    exit 1
fi

# Check if the result starts with "ERROR"
if [[ "$latest_backup" == ERROR* ]]; then
    echo "$latest_backup"
    exit 1
fi

echo "Latest backup found on remote server: $latest_backup"

# Just use the original backup name without adding a timestamp
DEST_DIR="${LOCAL_DIR}/${latest_backup}"
debug_echo "Local destination path: $DEST_DIR"

# Check if the directory already exists
if [ -d "$DEST_DIR" ]; then
    echo "Warning: Destination directory already exists. Old backup will be removed."
    rm -rf "$DEST_DIR"
fi

echo "Copying backup from remote server to $DEST_DIR..."

# Create the destination directory
mkdir -p "$DEST_DIR"

# Use SCP to copy the latest backup from the remote server
scp -r $REMOTE_HOST:"${REMOTE_DIR}/${latest_backup}/" "$DEST_DIR"

if [ $? -eq 0 ]; then
    echo "Backup successfully copied to $DEST_DIR"
else
    echo "Failed to copy backup from remote server"
    exit 1
fi

echo "Backup process completed successfully"
exit 0