#!/bin/bash

# Check if script is run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Please run again with sudo or as root user."
    exit 1
fi

# Variables

export SYSTEMD_SERVICE_PATH="/etc/systemd/system/devopsfetch.service"
export SCRIPT_PATH="/usr/local/bin/devopsfetch"
export SCRIPT_OPTIONS="-d -n -u -p"

# Create systemd service files
setup_systemd_service() {
    echo "Creating systemd service file at $SYSTEMD_SERVICE_PATH"
    envsubst < devopsfetch.service > "$SYSTEMD_SERVICE_PATH"
    

    echo "Reloading systemd manager configuration"
    sudo systemctl daemon-reload

    echo "Enabling devopsfetch service"
    sudo systemctl enable devopsfetch

    echo "Starting devopsfetch service"
    sudo systemctl start devopsfetch

    

}

setup_systemd_service

echo "Monitoring has been setup. devopsfetch is running in the background."
