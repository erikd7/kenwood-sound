#!/bin/bash

# Use this script to initialize Plexamp on the first run

# Check if there is an existing config
SHARED_CONFIG_DIR="/var/lib/plexamp/.local/share/Plexamp"
USER_CONFIG_DIR="$HOME/.local/share/Plexamp"
PLAYER_NAME_SETTING_SUB_DIR="/Settings/%40Plexamp%3Aplayer%3Aname"

# If no config exists in shared dir, check user dir and copy if found
if [ -z "$(ls -A "$SHARED_CONFIG_DIR$PLAYER_NAME_SETTING_SUB_DIR" 2>/dev/null)" ]; then
    echo "No existing Plexamp shared service config"
    if [ -z "$(cat "$USER_CONFIG_DIR$PLAYER_NAME_SETTING_SUB_DIR" 2>/dev/null)" ]; then
        echo "No existing Plexamp user config found. Initializing run required..."
        /opt/node/bin/node /usr/local/bin/plexamp/js/index.js
    fi
    
    echo "Copying existing Plexamp config from user directory to shared directory..."
    sudo mkdir -p "$SHARED_CONFIG_DIR"
    sudo cp -r "$USER_CONFIG_DIR/." "$SHARED_CONFIG_DIR/"
    sudo chown -R plexamp:plexamp "$SHARED_CONFIG_DIR"
else
    echo "Plexamp config already exists in shared directory, using existing config..."
fi

echo "Restarting Plexamp with new config..."
sudo systemctl restart plexamp.service