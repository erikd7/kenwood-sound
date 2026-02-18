#!/bin/bash
set -e

CONFIG="$1"
SNAPSERVER_NAME="$2"

# Early exit if librespot is disabled
USE_LIBRESPOT=$(jq -r '.snapserver.streams.librespot' "$CONFIG")
if [ "$USE_LIBRESPOT" != "true" ]; then
  exit 0
fi

echo "Generating go-librespot config"

LIB_CONFIG_DIR="/var/lib/librespot/.config/go-librespot"
LIB_CONFIG_FILE="$LIB_CONFIG_DIR/config.yml"
LIB_FIFO="/tmp/librespotfifo"

mkdir -p "$LIB_CONFIG_DIR"

# Ensure FIFO exists with librespot ownership
if [ ! -p "$LIB_FIFO" ]; then
  echo "Creating FIFO at $LIB_FIFO"
  rm -f "$LIB_FIFO"
  mkfifo "$LIB_FIFO" || true
fi

sudo chown librespot:librespot "$LIB_FIFO"

# Pull config values (no defaults)
DEVICE_TYPE=$(jq -r '.librespot.device_type' "$CONFIG")
BITRATE=$(jq -r '.librespot.bitrate' "$CONFIG")
INITIAL_VOLUME=$(jq -r '.librespot.initial_volume' "$CONFIG")
VOLUME_STEPS=$(jq -r '.librespot.volume_steps' "$CONFIG")

cat > "$LIB_CONFIG_FILE" <<EOF
log_level: info

device_name: $SNAPSERVER_NAME
device_type: $DEVICE_TYPE

audio_backend: pipe
audio_output_pipe: "$LIB_FIFO"
audio_output_pipe_format: s16le

bitrate: $BITRATE
initial_volume: $INITIAL_VOLUME
volume_steps: $VOLUME_STEPS

zeroconf_enabled: true

credentials:
  type: zeroconf
  zeroconf:
    persist_credentials: true
EOF

echo "go-librespot config written to $LIB_CONFIG_FILE"
