#!/bin/bash

# Function to install dependencies if they are not already installed
install_dependency() {
    if ! command -v $1 &>/dev/null; then
        echo "$1 not found, installing..."
        sudo apt install -y $1
    else
        echo "$1 is already installed"
    fi
}

# Update package list
echo "Updating Package List"
sudo apt-get update

# Install required dependencies
install_dependency lsof
install_dependency nginx
install_dependency jq
install_dependency docker.io
install_dependency logrotate

# Configure log rotate to rotate logs 
echo "Configuring Log Rotate"
sudo touch /etc/logrotate.d/devopsfetch 
sudo tee /etc/logrotate.d/devopsfetch > /dev/null <<EOL
/var/log/devopsfetch/*.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 0644 root root
}
EOL

#Log rotate at 2 AM every day.
0 2 * * * /usr/sbin/logrotate /etc/logrotate.d/devopsfetch




# Enable and start Docker service
echo "Enabling and starting Docker service"
sudo systemctl enable docker
sudo systemctl start docker

# Enable and start Nginx service
echo "Enabling and starting Nginx service"
sudo systemctl enable nginx
sudo systemctl start nginx

# Variables for the script setup
SCRIPT_NAME="devopsfetch.sh"
SCRIPT_PATH="/usr/local/bin/devopsfetch"


# Function to copy the script to /usr/local/bin
setup_script() {
    if [ ! -f "$SCRIPT_NAME" ]; then
        echo "Error: $SCRIPT_NAME not found in the current directory."
        exit 1
    fi
    echo ""
    echo ""
    echo "Copying $SCRIPT_NAME to $SCRIPT_PATH"
    sudo cp "$SCRIPT_NAME" "$SCRIPT_PATH"
    sudo chmod +x "$SCRIPT_PATH"
}

# Execute script setup
setup_script

echo ""
echo ""
echo ""
echo "All dependencies have been installed, and the devopsfetch tool is ready for usage."

echo ""
echo ""
devopsfetch -h
