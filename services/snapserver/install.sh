#!/bin/bash

ARCH=$1  # receive from top-level script
echo "Snapserver install running on $ARCH"

if [[ "$ARCH" == "aarch64" ]]; then
    SNAPCAST_ARCH="aarch64"
elif [[ "$ARCH" == "armv7l" ]]; then
    SNAPCAST_ARCH="armhf"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Installing snapserver..."
sudo apt install -y snapserver snapclient

# Set up snapserver user and directories
sudo useradd -r -s /usr/sbin/nologin snapserver 2>/dev/null || true
sudo mkdir -p /var/lib/snapserver
sudo chown -R snapserver:audio /var/lib/snapserver
sudo usermod -aG audio snapserver # Add snapserver user to audio group to access loopback device
