#!/bin/bash
set -e

CONFIG="/etc/kenwood-sound/device.json"
ENV_DIR="/etc/kenwood-sound"
ENV_FILE="$ENV_DIR/kenwood-sound.env"

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

echo "Wrote environment file to $ENV_FILE"

# Set hostname
hostnamectl set-hostname "$SYSTEM_NAME"

# ----------------------------
# Generate Snapserver Config
# ----------------------------

if [[ "$ROLE" == "server" || "$ROLE" == "both" ]]; then

  echo "Generating snapserver.conf"

  SNAP_CONF="/etc/snapserver.conf"
  TMP_CONF="/etc/snapserver.conf.tmp"

  AUDIO_PORT=$(jq -r '.snapserver.ports.audio // 1704' "$CONFIG")
  CONTROL_PORT=$(jq -r '.snapserver.ports.control // 1705' "$CONFIG")
  HTTP_PORT=$(jq -r '.snapserver.ports.http // 1780' "$CONFIG")

  CODEC=$(jq -r '.snapserver.codec // "flac"' "$CONFIG")
  SAMPLE_FORMAT=$(jq -r '.snapserver.sample_format // "48000:16:2"' "$CONFIG")
  BUFFER_MS=$(jq -r '.snapserver.buffer_ms // 100' "$CONFIG")

  USE_LIBRESPOT=$(jq -r '.snapserver.streams.librespot // true' "$CONFIG")
  USE_AIRPLAY=$(jq -r '.snapserver.streams.airplay // false' "$CONFIG")
  USE_PLEXAMP=$(jq -r '.snapserver.streams.plexamp // false' "$CONFIG")

  # Start config
  cat > "$TMP_CONF" <<EOF
[server]
port = $AUDIO_PORT
controlPort = $CONTROL_PORT
http_port = $HTTP_PORT
ipv6 = false
hostname = $SYSTEM_NAME

[http]
bindToAddress = 0.0.0.0

[stream]
bufferMs = $BUFFER_MS
codec = $CODEC
sampleFormat = $SAMPLE_FORMAT
EOF

  # ---- Stream Sources ----

  if [ "$USE_LIBRESPOT" = "true" ]; then
    LIB_BITRATE=$(jq -r '.librespot.bitrate // 320' "$CONFIG")
    LIB_VOL=$(jq -r '.librespot.initial_volume // 80' "$CONFIG")

    cat >> "$TMP_CONF" <<EOF
source = pipe:///tmp/librespotfifo?name=Snapcast-Spotify&bitrate=$LIB_BITRATE&normalize=true&disable_audio_cache=true&wd_timeout=7800&volume=$LIB_VOL
EOF
  fi

  if [ "$USE_AIRPLAY" = "true" ]; then
    cat >> "$TMP_CONF" <<EOF
source = airplay:///shairport-sync?name=Snapcast-Airplay&port=4483&devicename=$SYSTEM_NAME
EOF
  fi

  if [ "$USE_PLEXAMP" = "true" ]; then
    cat >> "$TMP_CONF" <<EOF
source = tcp:///0.0.0.0:4484?name=Plexamp&sampleformat=44100:16:2
EOF
  fi

  # ---- Logging ----
  cat >> "$TMP_CONF" <<EOF

[logging]
logFilter = *:info
sink = stdout
EOF

  # Atomic replace
  mv "$TMP_CONF" "$SNAP_CONF"

  echo "snapserver.conf written to $SNAP_CONF"

fi

# ----------------------------
# Generate go-librespot Config
# ----------------------------

if [[ "$ROLE" == "server" || "$ROLE" == "both" ]]; then

  USE_LIBRESPOT=$(jq -r '.snapserver.streams.librespot // true' "$CONFIG")

  if [ "$USE_LIBRESPOT" = "true" ]; then

    echo "Generating go-librespot config"

    LIB_HOME="/var/lib/librespot"
    LIB_CONFIG_DIR="$LIB_HOME/.config/go-librespot"
    LIB_CONFIG_FILE="$LIB_CONFIG_DIR/config.yml"
    LIB_FIFO="/tmp/librespotfifo"

    mkdir -p "$LIB_CONFIG_DIR"

    # Ensure FIFO exists
    if [ ! -p "$LIB_FIFO" ]; then
      echo "Creating FIFO at $LIB_FIFO"
      rm -f "$LIB_FIFO"
      mkfifo "$LIB_FIFO" || true
    fi

    # Pull config values
    DEVICE_TYPE=$(jq -r '.librespot.device_type // "speaker"' "$CONFIG")
    BITRATE=$(jq -r '.librespot.bitrate // 320' "$CONFIG")
    INITIAL_VOLUME=$(jq -r '.librespot.initial_volume // 80' "$CONFIG")
    VOLUME_STEPS=$(jq -r '.librespot.volume_steps // 100' "$CONFIG")

    cat > "$LIB_CONFIG_FILE" <<EOF
log_level: info

device_name: $SYSTEM_NAME
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

  fi
fi

# ----------------------------
# Generate Environment File
# ----------------------------

cat > "$ENV_FILE" <<EOF
SYSTEM_NAME=$SYSTEM_NAME
ROLE=$ROLE
EOF

echo "Configuration applied successfully."
