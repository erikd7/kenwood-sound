#!/bin/bash

# First run this: wget -O quick-start.sh https://raw.githubusercontent.com/erikd7/kenwood-sound/refs/tags/latest/quick-start.sh

echo "Kenwood sound quick start..."

echo "Removing old kenwood-sound if it exists..."
sudo rm -rf ~/kenwood-sound-latest
sudo rm ~/kenwood-sound.zip
sudo rm -rf /opt/kenwood-sound

echo "Downloading latest kenwood-sound..."
wget -O kenwood-sound.zip https://github.com/erikd7/kenwood-sound/archive/refs/tags/latest.zip

echo "Extracting kenwood-sound..."
sudo unzip kenwood-sound.zip

sudo mkdir -p /opt/kenwood-sound

echo "Moving kenwood-sound to /opt..."
sudo mv -f kenwood-sound-latest/* /opt/kenwood-sound

echo "Cleaning up zip and extracted folder..."
sudo rm -rf ~/kenwood-sound-latest
sudo rm ~/kenwood-sound.zip

echo "Changing directory to /opt/kenwood-sound..."
cd /opt/kenwood-sound

echo "Set your device config here (see readme and /config for examples):"
sudo nano config/device.json

make install

# Load generated environment file if present so ROLE and other vars are available
ENV_FILE=/etc/kenwood-sound/kenwood-sound.env
if [ -f "$ENV_FILE" ]; then
	# shellcheck disable=SC1090
	. "$ENV_FILE"
fi

# Check USE_PLEXAMP from setup, and if true let user do required inline Plexamp setup before starting services
if [ "${USE_PLEXAMP:-false}" = "true" ]; then
	echo "Initializing Plexamp..."
	sudo sh services/plexamp/initialize.sh
fi

echo "Starting services..."
sudo systemctl start kenwood-sound

echo "Enjoy!"