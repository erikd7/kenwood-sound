#!/bin/bash
set -e

ARCH=$1
CONFIG="/etc/kenwood-sound/device.json"

# Early exit if snapweb not needed
if [ -f "$CONFIG" ]; then
  ROLE=$(jq -r '.role // "client"' "$CONFIG")
  if [[ "$ROLE" != "server" && "$ROLE" != "both" ]]; then
    echo "Snapweb not needed for role: $ROLE"
    exit 0
  fi
  
  USE_SNAPWEB=$(jq -r '.snapweb.enabled // false' "$CONFIG")
  if [ "$USE_SNAPWEB" != "true" ]; then
    echo "Snapweb not enabled in config"
    exit 0
  fi
fi

echo "Snapweb install running on $ARCH"
echo "Snapweb is installed as part of snapserver"