#!/bin/bash
set -e

ARCH=$1
CONFIG="/etc/kenwood-sound/device.json"

# Early exit if snapserver not needed
if [ -f "$CONFIG" ]; then
  ROLE=$(jq -r '.role // "server"' "$CONFIG")
  if [[ "$ROLE" != "server" && "$ROLE" != "both" ]]; then
    echo "Snapserver not needed for role: $ROLE"
    exit 0
  fi
fi

echo "Snapserver install running on $ARCH"

echo "Installing snapserver..."
sudo apt install -y snapserver

# Set up snapserver user and directories
sudo useradd -r -s /usr/sbin/nologin snapserver 2>/dev/null || true
sudo mkdir -p /var/lib/snapserver
sudo chown -R snapserver:audio /var/lib/snapserver
sudo usermod -aG audio snapserver # Add snapserver user to audio group to access loopback device
