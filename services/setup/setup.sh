#!/bin/bash
set -e

CONFIG="/etc/kenwood-sound/device.json"
ENV_DIR="/etc/kenwood-sound"
ENV_FILE="$ENV_DIR/kenwood-sound.env"
CONFIG_BIN_DIR="/usr/local/bin"

echo "Applying configuration from device.json"

if [ ! -f "$CONFIG" ]; then
  echo "device.json missing"
  exit 1
fi

# Ensure config directory exists
mkdir -p "$ENV_DIR"

# Ensure jq exists (fail cleanly instead of installing during boot)
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not installed. Install it during image build."
  exit 1
fi

# Parse base config
SYSTEM_NAME=$(jq -r '.system_name' "$CONFIG")
ROLE=$(jq -r '.role' "$CONFIG")
DEVICE_NAME=$(jq -r '.device_name // ""' "$CONFIG")
SNAP_HOST=$(jq -r '.snapclient.server_host // "127.0.0.1"' "$CONFIG")
SNAP_PORT=$(jq -r '.snapclient.server_port // 1704' "$CONFIG")
SNAP_SOUNDCARD=$(jq -r '.snapclient.output_device // "default"' "$CONFIG")

# Set hostname
hostnamectl set-hostname "$SYSTEM_NAME"

# ----------------------------
# Call service-specific setup scripts
# ----------------------------

if [ -f "$CONFIG_BIN_DIR/kenwood-sound-snapserver-setup" ]; then
  "$CONFIG_BIN_DIR/kenwood-sound-snapserver-setup" "$CONFIG" "$SYSTEM_NAME" "$ROLE"
fi

if [ -f "$CONFIG_BIN_DIR/kenwood-sound-librespot-setup" ]; then
  "$CONFIG_BIN_DIR/kenwood-sound-librespot-setup" "$CONFIG" "$SYSTEM_NAME"
fi

if [ -f "$CONFIG_BIN_DIR/kenwood-sound-shairport-setup" ]; then
  "$CONFIG_BIN_DIR/kenwood-sound-shairport-setup" "$CONFIG" "$SYSTEM_NAME"
fi

if [ -f "$CONFIG_BIN_DIR/kenwood-sound-plexamp-setup" ]; then
  "$CONFIG_BIN_DIR/kenwood-sound-plexamp-setup" "$CONFIG" "$ROLE"
fi

# ----------------------------
# Generate Environment File
# ----------------------------

cat > "$ENV_FILE" <<EOF
SYSTEM_NAME=$SYSTEM_NAME
ROLE=$ROLE
DEVICE_NAME=$DEVICE_NAME
SNAP_HOST=$SNAP_HOST
SNAP_PORT=$SNAP_PORT
SNAP_SOUNDCARD=$SNAP_SOUNDCARD
EOF

echo "Configuration applied successfully."
