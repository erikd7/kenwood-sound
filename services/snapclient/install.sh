#!/bin/bash

ARCH=$1
echo "Snapclient install running on $ARCH"

echo "Installing snapclient..."
sudo apt install -y snapclient

# Set up snapclient user and directories
sudo useradd -r -s /usr/sbin/nologin snapclient 2>/dev/null || true
sudo mkdir -p /var/lib/snapclient
sudo chown -R snapclient:audio /var/lib/snapclient
sudo usermod -aG audio snapclient # Add snapclient user to audio group to access loopback device
