#!/bin/bash
set -e

CONFIG="$1"
SYSTEM_NAME="$2"
ROLE="$3"

# Early exit if not server
if [[ "$ROLE" != "server" && "$ROLE" != "both" ]]; then
  exit 0
fi

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
USE_HOST_AUDIO=$(jq -r '.snapserver.streams.host_audio // false' "$CONFIG")

# Start config
cat > "$TMP_CONF" <<EOF
[server]
port = $AUDIO_PORT
controlPort = $CONTROL_PORT
http_port = $HTTP_PORT
ipv6 = false
hostname = $SYSTEM_NAME
sink = null

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
source = pipe:///tmp/librespotfifo?name=Spotify&sampleformat=44100:16:2&bitrate=$LIB_BITRATE&normalize=true&disable_audio_cache=true&wd_timeout=7800&volume=$LIB_VOL
EOF
fi

if [ "$USE_AIRPLAY" = "true" ]; then
  cat >> "$TMP_CONF" <<EOF
source = pipe:///tmp/airplayfifo?name=Airplay&sampleformat=44100:16:2&wd_timeout=7800
EOF
fi

if [ "$USE_PLEXAMP" = "true" ]; then
  cat >> "$TMP_CONF" <<EOF
source = alsa:///?name=Plexamp&device=plexamp_in&sampleformat=44100:16:2
EOF
fi

if [ "$USE_HOST_AUDIO" = "true" ]; then
  HOST_AUDIO_NAME=$(jq -r '.host_audio.name // "System Audio"' "$CONFIG")
  HOST_AUDIO_DEVICE=$(jq -r '.host_audio.device // "hw:CARD=AUDIO,DEV=0"' "$CONFIG")
  HOST_AUDIO_FORMAT=$(jq -r '.host_audio.sample_format // "48000:16:2"' "$CONFIG")

  cat >> "$TMP_CONF" <<EOF
source = alsa:///?name=$HOST_AUDIO_NAME&device=$HOST_AUDIO_DEVICE&sampleformat=$HOST_AUDIO_FORMAT
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
