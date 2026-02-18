#!/bin/bash
set -e

CONFIG="$1"
SNAPSERVER_NAME="$2"
ROLE="$3"

# Early exit if not server
if [[ "$ROLE" != "server" && "$ROLE" != "both" ]]; then
  exit 0
fi

echo "Generating snapserver.conf"

SNAP_CONF="/etc/snapserver.conf"
TMP_CONF="/etc/snapserver.conf.tmp"

AUDIO_PORT=$(jq -r '.snapserver.ports.audio' "$CONFIG")
CONTROL_PORT=$(jq -r '.snapserver.ports.control' "$CONFIG")
HTTP_PORT=$(jq -r '.snapserver.ports.http' "$CONFIG")

CODEC=$(jq -r '.snapserver.codec' "$CONFIG")
SAMPLE_FORMAT=$(jq -r '.snapserver.sample_format' "$CONFIG")
BUFFER_MS=$(jq -r '.snapserver.buffer_ms' "$CONFIG")

USE_LIBRESPOT=$(jq -r '.snapserver.streams.librespot' "$CONFIG")
USE_AIRPLAY=$(jq -r '.snapserver.streams.airplay' "$CONFIG")
USE_PLEXAMP=$(jq -r '.snapserver.streams.plexamp' "$CONFIG")
USE_HOST_AUDIO=$(jq -r '.snapserver.streams.host_audio' "$CONFIG")

LIBRESPOT_NAME=$(jq -r '.librespot.stream_name' "$CONFIG")
AIRPLAY_NAME=$(jq -r '.airplay.stream_name' "$CONFIG")
PLEXAMP_NAME=$(jq -r '.plexamp.stream_name' "$CONFIG")
HOST_AUDIO_NAME=$(jq -r '.host_audio.stream_name' "$CONFIG")

# Start config
cat > "$TMP_CONF" <<EOF
[server]
port = $AUDIO_PORT
controlPort = $CONTROL_PORT
http_port = $HTTP_PORT
ipv6 = false
hostname = $SNAPSERVER_NAME
sink = null

[http]
bindToAddress = 0.0.0.0

[stream]
bufferMs = $BUFFER_MS
codec = $CODEC
sampleFormat = $SAMPLE_FORMAT
EOF

# Stream Sources

if [ "$USE_LIBRESPOT" = "true" ]; then
  LIB_BITRATE=$(jq -r '.librespot.bitrate' "$CONFIG")
  LIB_VOL=$(jq -r '.librespot.initial_volume' "$CONFIG")

  cat >> "$TMP_CONF" <<EOF
source = pipe:///tmp/librespotfifo?name=$LIBRESPOT_NAME&sampleformat=44100:16:2&bitrate=$LIB_BITRATE&normalize=true&disable_audio_cache=true&wd_timeout=7800&volume=$LIB_VOL
EOF
fi

if [ "$USE_AIRPLAY" = "true" ]; then
  cat >> "$TMP_CONF" <<EOF
source = pipe:///tmp/airplayfifo?name=$AIRPLAY_NAME&sampleformat=44100:16:2&wd_timeout=7800
EOF
fi

if [ "$USE_PLEXAMP" = "true" ]; then
  cat >> "$TMP_CONF" <<EOF
source = alsa:///?name=$PLEXAMP_NAME&device=plexamp_in&sampleformat=44100:16:2
EOF
fi

if [ "$USE_HOST_AUDIO" = "true" ]; then
  HOST_AUDIO_DEVICE=$(jq -r '.host_audio.device' "$CONFIG")
  HOST_AUDIO_FORMAT=$(jq -r '.host_audio.sample_format' "$CONFIG")

  cat >> "$TMP_CONF" <<EOF
source = alsa:///?name=$HOST_AUDIO_NAME&device=$HOST_AUDIO_DEVICE&sampleformat=$HOST_AUDIO_FORMAT
EOF
fi

# Logging
cat >> "$TMP_CONF" <<EOF

[logging]
logFilter = *:info
sink = stdout
EOF

# Atomic replace
mv "$TMP_CONF" "$SNAP_CONF"

echo "snapserver.conf written to $SNAP_CONF"
