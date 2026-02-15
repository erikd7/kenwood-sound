#!/bin/bash
set -e

ARCH=$1
CONFIG="/etc/kenwood-sound/device.json"

# Early exit if snapclient not needed
if [ -f "$CONFIG" ]; then
  ROLE=$(jq -r '.role // "client"' "$CONFIG")
  if [[ "$ROLE" != "client" && "$ROLE" != "both" ]]; then
    echo "Snapclient not needed for role: $ROLE"
    exit 0
  fi
fi

echo "Snapclient install running on $ARCH"

echo "Installing snapclient..."
sudo apt install -y snapclient

# Set up snapclient user and directories
sudo useradd -r -s /usr/sbin/nologin snapclient 2>/dev/null || true
sudo mkdir -p /var/lib/snapclient
sudo chown -R snapclient:audio /var/lib/snapclient
sudo usermod -aG audio snapclient # Add snapclient user to audio group to access loopback device
