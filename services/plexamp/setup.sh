#!/bin/bash
set -e

CONFIG="$1"
ROLE="$2"

USE_PLEXAMP=$(jq -r '.snapserver.streams.plexamp // false' "$CONFIG")
if [ "$USE_PLEXAMP" != "true" ]; then
  exit 0
fi

# Ensure ALSA loopback kernel module is loaded
if ! lsmod | grep -q '^snd_aloop\b'; then
  echo "Loading snd-aloop kernel module"
  modprobe snd-aloop || true
fi
