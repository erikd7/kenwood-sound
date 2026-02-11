#!/bin/bash

# Runs on first boot to configure the device based on the settings in device.json

CONFIG="/etc/audio/device.json"

MODE=$(jq -r '.mode' $CONFIG)
NAME=$(jq -r '.device_name' $CONFIG)
SERVER=$(jq -r '.snapserver_host' $CONFIG)

# Set hostname
hostnamectl set-hostname "$NAME"

# Configure librespot
LIBRESPOT_ARGS="--name \"$NAME\" --bitrate 320 --backend pipe --device-type speaker --format S16"

if [ "$MODE" = "server" ] || [ "$MODE" = "both" ]; then
    systemctl enable snapserver
fi

if [ "$MODE" = "client" ] || [ "$MODE" = "both" ]; then
    systemctl enable snapclient
    sed -i "s/^SNAPSERVER_HOST=.*/SNAPSERVER_HOST=$SERVER/" /etc/default/snapclient
fi

systemctl enable librespot
