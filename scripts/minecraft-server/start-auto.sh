#!/bin/bash

# Configuration
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1339462317296979998/YQkps4mGFikyDrjnnPFwfmcngds4YAKqGLvnqtrm6HBAe_OLcZgbMFDsPdZeq68pB_7b"
SCREEN_NAME="serv"
MONITOR_SCREEN_NAME="mon"
LOG_FILE="/home/opc/logs/latest.log"
RESTART_LOG="/home/opc/restart.log"  # File to store restart count and timestamp

# Function to send a Discord notification
send_discord_notification() {
    local message="$1"
    curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"$message\"}" "$DISCORD_WEBHOOK"
}

# Initialize restart count and date if not set
if [ ! -f "$RESTART_LOG" ]; then
    echo "0 $(date "+%Y-%m-%d")" > "$RESTART_LOG"
fi

# Check if the Minecraft server is already running in screen
if screen -list | grep -q "$SCREEN_NAME"; then
    echo "Minecraft server is already running in screen session '$SCREEN_NAME'."
else
    # Start the Minecraft server in a detached screen session
    echo "Starting Minecraft server in a screen session..."
    send_discord_notification ":pick: Minecraft server is starting..."
    screen -dmS $SCREEN_NAME java -Xmx1024M -Xms1024M -jar server.jar nogui
fi

# Start the monitor screen first
if ! screen -list | grep -q "$MONITOR_SCREEN_NAME"; then
    echo "Starting server monitoring in a separate screen session..."
    screen -dmS $MONITOR_SCREEN_NAME
    
    # Wait a bit for screen to initialize
    sleep 2

    # Send the monitoring script as a heredoc to a temporary file
    cat << EOF > /tmp/monitor_script.sh
#!/bin/bash

# Import configuration
LOG_FILE="$LOG_FILE"
RESTART_LOG="$RESTART_LOG"
DISCORD_WEBHOOK="$DISCORD_WEBHOOK"
SCREEN_NAME="$SCREEN_NAME"

# Additional paths
WORLD_PATH="/home/opc/world"
CRASHED_WORLDS="/home/opc/crashed-worlds"
BACKUP_WORLDS="/home/opc/backup-worlds"
ADMIN_LOG="/home/opc/admin-logs.txt"

# Function to log admin actions
log_admin() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> "\$ADMIN_LOG"
}

# Function to get latest backup world
get_latest_backup() {
    find "\$BACKUP_WORLDS" -maxdepth 1 -type d -name "world*" -printf '%T@ %p\n' | \
    sort -nr | \
    head -n1 | \
    cut -d' ' -f2-
}

# Function to handle world backup and restoration
handle_world_crash() {
    # Get current timestamp
    timestamp=\$(date '+%d%m%Y-%H%M')
    
    # First ensure the server process is completely stopped
    if screen -list | grep -q "\$SCREEN_NAME"; then
        # Try graceful shutdown first
        screen -S "\$SCREEN_NAME" -X stuff "stop$(printf '\r')"
        sleep 5
        
        # Force kill if still running
        pkill -f "screen.*\$SCREEN_NAME"
        sleep 2
        
        # Kill Java process if it's still hanging
        pkill -f "java.*server.jar"
        sleep 2
    fi
    
    # Move current crashed world to crashed-worlds
    if [ -d "\$WORLD_PATH" ]; then
        mkdir -p "\$CRASHED_WORLDS"
        # Completely move the crashed world
        mv "\$WORLD_PATH" "\$CRASHED_WORLDS/world\$timestamp"
        log_admin "Moved crashed world to: \$CRASHED_WORLDS/world\$timestamp"
        echo "Monitor: Moved crashed world to: \$CRASHED_WORLDS/world\$timestamp"
    fi

    # Get latest backup
    latest_backup=\$(get_latest_backup)
    if [ -n "\$latest_backup" ]; then
        # Copy the latest backup directly to the world path
        cp -r "\$latest_backup" "\$WORLD_PATH"
        log_admin "Restored backup: \$latest_backup"
        echo "Monitor: Restored backup: \$latest_backup"
        return 0
    else
        log_admin "ERROR: No backup found to restore!"
        echo "Monitor: ERROR: No backup found to restore!"
        return 1
    fi
}

echo 'Starting monitor...'

# Get current date and last restart date
current_date=\$(date '+%Y-%m-%d')
last_restart_date=\$(awk '{print \$2}' "\$RESTART_LOG")

# Reset restart count if a new day
if [ "\$current_date" != "\$last_restart_date" ]; then
    echo "0 \$current_date" > "\$RESTART_LOG"
fi

# Get the current restart count
restart_count=\$(awk '{print \$1}' "\$RESTART_LOG")

# Check if the log file exists before proceeding
if [ ! -f "\$LOG_FILE" ]; then
    echo "Error: Log file not found: \$LOG_FILE"
    exit 1
fi

echo 'Monitoring log file...'

# Create the log file if it doesn't exist and start monitoring from the end
touch "\$LOG_FILE"
tail -F -n0 "\$LOG_FILE" | while read -r line; do
    # Check for player join message
    if [[ "\$line" == *"joined the game"* ]]; then
        player_name=\$(echo "\$line" | grep -oP '(?<=: ).*(?= joined the game)')
        echo "Monitor: Player joined: \$player_name"
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\":\":green_heart: \$player_name joined the game\"}" \
             "\$DISCORD_WEBHOOK"
    fi

    # Check for player leave message
    if [[ "\$line" == *"left the game"* ]]; then
        player_name=\$(echo "\$line" | grep -oP '(?<=: ).*(?= left the game)')
        echo "Monitor: Player left: \$player_name"
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\":\":red_circle: \$player_name left the game\"}" \
             "\$DISCORD_WEBHOOK"
    fi

    # Check for crash message
    if [[ "\$line" == *"[Server Watchdog/FATAL]: Considering it to be crashed"* ]]; then
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - Server crashed!"
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\":\":warning: Minecraft server crashed!\"}" \
             "\$DISCORD_WEBHOOK"
        
        # Check restart count and reboot if under 3
        if [ "\$restart_count" -lt 3 ]; then
            curl -H "Content-Type: application/json" \
                 -X POST \
                 -d "{\"content\":\":arrows_counterclockwise: Backing up world and attempting server restore...\"}" \
                 "\$DISCORD_WEBHOOK"

            # Handle world backup and restoration
            handle_world_crash
            
            echo "\$(date '+%Y-%m-%d %H:%M:%S') - Restarting Minecraft server..."
            
            # Wait for the old screen to terminate (up to 30 seconds)
            max_wait=30
            wait_time=0
            while screen -list | grep -q "\$SCREEN_NAME" && [ \$wait_time -lt \$max_wait ]; do
                sleep 1
                wait_time=\$((wait_time + 1))
            done

            # Create new screen and start server
            screen -dmS "\$SCREEN_NAME" java -Xmx1024M -Xms1024M -jar server.jar nogui
            
            curl -H "Content-Type: application/json" \
                 -X POST \
                 -d "{\"content\":\":white_check_mark: Minecraft server restarted with restored backup.\"}" \
                 "\$DISCORD_WEBHOOK"
            
            restart_count=\$((restart_count + 1))
            echo "\$restart_count \$current_date" > "\$RESTART_LOG"
            log_admin "Server restarted after crash (Attempt \$restart_count)"
            echo "Monitor: Server restarted after crash (Attempt \$restart_count)"
        else
            curl -H "Content-Type: application/json" \
                 -X POST \
                 -d "{\"content\":\":x: Maximum restart attempts (3) reached for today. Server will remain offline.\"}" \
                 "\$DISCORD_WEBHOOK"
            echo "\$(date '+%Y-%m-%d %H:%M:%S') - Maximum reboots reached for today!"
            log_admin "Maximum daily restart limit reached after crash"
            echo "Monitor: Maximum daily restart limit reached after crash"
        fi
    fi
done
EOF

    # Make the script executable
    chmod +x /tmp/monitor_script.sh

    # Send the script path to the screen session and execute it
    screen -S "$MONITOR_SCREEN_NAME" -X stuff "/tmp/monitor_script.sh$(printf '\015')"
else
    echo "Monitor screen is already running."
fi

# Exit the script immediately so you can use your terminal freely
echo "Minecraft server and monitoring started in screen. You can reattach to the Minecraft server with: screen -r $SCREEN_NAME"
echo "You can reattach to the monitoring session with: screen -r $MONITOR_SCREEN_NAME"
exit 0
