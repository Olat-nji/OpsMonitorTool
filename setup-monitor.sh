#!/bin/bash

# Check if script is run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Please run again with sudo or as root user."
    exit 1
fi

# Variables

export SYSTEMD_SERVICE_PATH="/etc/systemd/system/devops-fetch.service"
export SCRIPT_PATH="/usr/local/bin/devops-fetch"
export SCRIPT_OPTIONS="-d -n -u -p"

# Create systemd service files
setup_systemd_service() {
    echo "Creating systemd service file at $SYSTEMD_SERVICE_PATH"
    envsubst < devops-fetch.service > "$SYSTEMD_SERVICE_PATH"
    

    echo "Reloading systemd manager configuration"
    sudo systemctl daemon-reload

    echo "Enabling devops-fetch service"
    sudo systemctl enable devops-fetch

    echo "Starting devops-fetch service"
    sudo systemctl start devops-fetch

    

}

setup_systemd_service

echo "Monitoring has been setup. devops-fetch is running in the background."
