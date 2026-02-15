#!/bin/bash
set -e

ARCH=$1
CONFIG="/etc/kenwood-sound/device.json"

# Early exit if airplay not needed
if [ -f "$CONFIG" ]; then
  USE_AIRPLAY=$(jq -r '.snapserver.streams.airplay // false' "$CONFIG")
  if [[ "$USE_AIRPLAY" != "true" ]]; then
    echo "Airplay is disabled, skipping installation..."
    exit 0
  fi
fi

echo "shairport-sync install running on $ARCH"

echo "Installing shairport-sync..."
sudo apt install -y shairport-sync

# Disable the default shairport-sync service (we manage our own unit)
sudo systemctl stop shairport-sync.service 2>/dev/null || true
sudo systemctl disable shairport-sync.service 2>/dev/null || true
sudo systemctl mask shairport-sync.service 2>/dev/null || true

# The apt package creates the shairport-sync user; ensure it's in audio group
sudo usermod -aG audio shairport-sync
