#!/bin/bash

# First run this: wget -O quick-start.sh https://raw.githubusercontent.com/erikd7/kenwood-sound/refs/heads/main/quick-start.sh

echo "Kenwood sound quick start..."

wget -O kenwood-sound.zip https://github.com/erikd7/kenwood-sound/archive/refs/heads/main.zip

sudo unzip -d kenwood-sound kenwood-sound.zip

sudo mkdir /opt/kenwood-sound

sudo mv -f kenwood-sound-main/* /opt/kenwood-sound

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