#!/bin/bash

ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

sudo apt install jq -y

bash ./services/snapserver/install.sh "$ARCH"
bash ./services/snapclient/install.sh "$ARCH"
bash ./services/plexamp/install.sh "$ARCH"
bash ./services/librespot/install.sh "$ARCH"
bash ./services/shairport-sync/install.sh "$ARCH"
