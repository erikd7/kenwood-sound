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
sudo apt update
sudo apt install -y snapserver snapclient
