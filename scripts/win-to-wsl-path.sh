#!/bin/bash

# Function to convert Windows path to WSL2 path
convert_to_wsl() {
    # Replace backslashes with forward slashes
    path="${1//\\//}"
    
    # Remove the drive letter (e.g. "C:")
    drive="${path:0:1}"
    path="${path:2}"
    
    # Convert to WSL2 path format
    wsl_path="/mnt/${drive,,}${path}"
    
    # Escape spaces with backslashes
    wsl_path=$(echo "$wsl_path" | sed 's/ /\\ /g')

    # Output the result
    echo "$wsl_path"
}

# Example usage
# Usage: ./script.sh "C:\Program Files\Adobe\Adobe Premiere Pro 2024"
convert_to_wsl "$1"
