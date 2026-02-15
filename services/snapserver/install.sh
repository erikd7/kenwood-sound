#!/bin/bash

ARCH=$1
echo "Snapserver install running on $ARCH"

echo "Installing snapserver..."
sudo apt install -y snapserver

# Set up snapserver user and directories
sudo useradd -r -s /usr/sbin/nologin snapserver 2>/dev/null || true
sudo mkdir -p /var/lib/snapserver
sudo chown -R snapserver:audio /var/lib/snapserver
sudo usermod -aG audio snapserver # Add snapserver user to audio group to access loopback device
