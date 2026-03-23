#!/bin/bash
set -e

ARCH=$1
CONFIG="/etc/kenwood-sound/device.json"
DOC_ROOT="/usr/share/snapserver/snapweb"

# Early exit if snapweb not needed
if [ -f "$CONFIG" ]; then
  ROLE=$(jq -r '.role // "client"' "$CONFIG")
  if [[ "$ROLE" != "server" && "$ROLE" != "both" ]]; then
    echo "Snapweb not needed for role: $ROLE"
    exit 0
  fi
  
  USE_SNAPWEB=$(jq -r '.snapweb.enabled // false' "$CONFIG")
  USE_KENWOOD_SOUND_UI=$(jq -r '.kenwood_sound_ui.enabled // false' "$CONFIG")
  if [ "$USE_SNAPWEB" != "true" ] && [ "$USE_KENWOOD_SOUND_UI" != "true" ]; then
    echo "Snapweb not enabled in config"
    exit 0
  fi
fi

echo "Installing snapweb files"
wget -O snapweb.zip https://github.com/snapcast/snapweb/releases/download/v0.9.3/snapweb.zip
sudo unzip -o snapweb.zip -d snapweb
sudo mkdir -p "$DOC_ROOT"
sudo rm -rf "$DOC_ROOT"/*
sudo mv -f snapweb/* "$DOC_ROOT"
rm -rf snapweb snapweb.zip

echo "Snapweb installed"
