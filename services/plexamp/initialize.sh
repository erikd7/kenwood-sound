#!/bin/bash
set -euo pipefail

FORCE_REFRESH="${1:-}"

# Accept common truthy values for force refresh
case "${FORCE_REFRESH,,}" in
    1|true|yes|force|-f) FORCE=true ;; 
    *) FORCE=false ;;
esac

# Use this script to initialize Plexamp on the first run

# Check if there is an existing config
SHARED_CONFIG_DIR="/var/lib/plexamp/.local/share/Plexamp"
USER_CONFIG_DIR="$HOME/.local/share/Plexamp"
PLAYER_NAME_SETTING_SUB_DIR="/Settings/%40Plexamp%3Aplayer%3Aname"

# If no config exists in shared dir, check user dir and copy if found
echo "Checking for existing Plexamp config in shared directory $SHARED_CONFIG_DIR$PLAYER_NAME_SETTING_SUB_DIR..."

if [ "$FORCE" = true ]; then
    echo "Force refresh enabled: re-initializing Plexamp and copying user config to shared directory (will overwrite)."
    sudo rm -rf "$SHARED_CONFIG_DIR"
    sudo rm -rf "$USER_CONFIG_DIR"
    
    /opt/node/bin/node /usr/local/bin/plexamp/js/index.js

    if [ -d "$USER_CONFIG_DIR" ] && [ "$(ls -A "$USER_CONFIG_DIR" 2>/dev/null)" ]; then
        echo "Copying Plexamp config from user directory to shared directory..."
        sudo mkdir -p "$SHARED_CONFIG_DIR"
        sudo cp -r "$USER_CONFIG_DIR/." "$SHARED_CONFIG_DIR/"
        sudo chown -R plexamp:plexamp "$SHARED_CONFIG_DIR"
    else
        echo "No user config found to copy after forced init."
    fi
else
    if [ -z "$(ls -A "$SHARED_CONFIG_DIR$PLAYER_NAME_SETTING_SUB_DIR" 2>/dev/null)" ]; then
        echo "No existing Plexamp shared service config"
        echo "Checking for existing Plexamp config in user directory $USER_CONFIG_DIR$PLAYER_NAME_SETTING_SUB_DIR..."
        if [ -f "$USER_CONFIG_DIR$PLAYER_NAME_SETTING_SUB_DIR" ] && [ -s "$USER_CONFIG_DIR$PLAYER_NAME_SETTING_SUB_DIR" ]; then
            echo "User config found; copying to shared directory..."
            sudo mkdir -p "$SHARED_CONFIG_DIR"
            sudo cp -r "$USER_CONFIG_DIR/." "$SHARED_CONFIG_DIR/"
            sudo chown -R plexamp:plexamp "$SHARED_CONFIG_DIR"
        else
            echo "No existing Plexamp user config found. Initializing run required..."
            /opt/node/bin/node /usr/local/bin/plexamp/js/index.js
        fi
    else
        echo "Plexamp config already exists in shared directory, using existing config..."
    fi
fi

echo "Restarting Plexamp with new config..."
sudo systemctl restart plexamp.service