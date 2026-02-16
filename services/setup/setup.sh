#!/bin/bash
set -e

DEVICE_CONFIG="/etc/kenwood-sound/device.json"
DEFAULT_CONFIG="/etc/kenwood-sound/default.device.json"
ENV_DIR="/etc/kenwood-sound"
ENV_FILE="$ENV_DIR/kenwood-sound.env"
CONFIG_BIN_DIR="/usr/local/bin"
MERGED_CONFIG="/tmp/merged-config.json"

echo "Applying configuration from device.json"

if [ ! -f "$DEVICE_CONFIG" ]; then
  echo "device.json missing"
  exit 1
fi

if [ ! -f "$DEFAULT_CONFIG" ]; then
  echo "default.device.json missing"
  exit 1
fi

# Ensure config directory exists
mkdir -p "$ENV_DIR"

# Ensure jq exists (fail cleanly instead of installing during boot)
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not installed. Install it during image build."
  exit 1
fi

# Merge device.json with default.device.json (device overrides defaults)
jq -s '.[0] * .[1]' "$DEFAULT_CONFIG" "$DEVICE_CONFIG" > "$MERGED_CONFIG"
CONFIG="$MERGED_CONFIG"

# Parse base config (from merged config, no inline defaults)
DEVICE_NAME=$(jq -r '.device_name' "$CONFIG")
ROLE=$(jq -r '.role' "$CONFIG")
SNAPSERVER_NAME=$(jq -r '.snapserver.name' "$CONFIG")
SNAP_HOST=$(jq -r '.snapclient.server_host' "$CONFIG")
SNAP_PORT=$(jq -r '.snapclient.server_port' "$CONFIG")
SNAP_SOUNDCARD=$(jq -r '.snapclient.output_device' "$CONFIG")

# Set hostname to device_name
hostnamectl set-hostname "$DEVICE_NAME"

# ----------------------------
# Call service-specific setup scripts
# ----------------------------

if [ -f "$CONFIG_BIN_DIR/kenwood-sound-snapserver-setup" ]; then
  "$CONFIG_BIN_DIR/kenwood-sound-snapserver-setup" "$CONFIG" "$SNAPSERVER_NAME" "$ROLE"
fi

if [ -f "$CONFIG_BIN_DIR/kenwood-sound-librespot-setup" ]; then
  "$CONFIG_BIN_DIR/kenwood-sound-librespot-setup" "$CONFIG" "$SNAPSERVER_NAME"
fi

if [ -f "$CONFIG_BIN_DIR/kenwood-sound-shairport-setup" ]; then
  "$CONFIG_BIN_DIR/kenwood-sound-shairport-setup" "$CONFIG" "$SNAPSERVER_NAME"
fi

if [ -f "$CONFIG_BIN_DIR/kenwood-sound-plexamp-setup" ]; then
  "$CONFIG_BIN_DIR/kenwood-sound-plexamp-setup" "$CONFIG" "$ROLE"
fi

# ----------------------------
# Generate Environment File
# ----------------------------

cat > "$ENV_FILE" <<EOF
DEVICE_NAME=$DEVICE_NAME
ROLE=$ROLE
SNAPSERVER_NAME=$SNAPSERVER_NAME
SNAP_HOST=$SNAP_HOST
SNAP_PORT=$SNAP_PORT
SNAP_SOUNDCARD=$SNAP_SOUNDCARD
EOF

echo "Configuration applied successfully."

# Cleanup
rm -f "$MERGED_CONFIG"
