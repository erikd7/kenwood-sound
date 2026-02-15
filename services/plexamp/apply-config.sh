#!/bin/bash
set -e

ROLE="$1"

if [[ "$ROLE" == "server" || "$ROLE" == "both" ]]; then
  # Ensure ALSA loopback kernel module is loaded
  if ! lsmod | grep -q '^snd_aloop\b'; then
    echo "Loading snd-aloop kernel module"
    modprobe snd-aloop || true
  fi
fi
