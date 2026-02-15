#!/bin/bash
set -e

ARCH=$1
echo "shairport-sync install running on $ARCH"

echo "Installing shairport-sync..."
sudo apt install -y shairport-sync

# Disable the default shairport-sync service (we manage our own unit)
sudo systemctl stop shairport-sync.service 2>/dev/null || true
sudo systemctl disable shairport-sync.service 2>/dev/null || true
sudo systemctl mask shairport-sync.service 2>/dev/null || true

# The apt package creates the shairport-sync user; ensure it's in audio group
sudo usermod -aG audio shairport-sync
