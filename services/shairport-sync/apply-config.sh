#!/bin/bash
set -e

CONFIG="$1"
SYSTEM_NAME="$2"

USE_AIRPLAY=$(jq -r '.snapserver.streams.airplay // false' "$CONFIG")

if [ "$USE_AIRPLAY" = "true" ]; then

  echo "Generating shairport-sync config"

  AIRPLAY_FIFO="/tmp/airplayfifo"
  AIRPLAY_CONF="/etc/shairport-sync.conf"

  # Ensure FIFO exists
  if [ ! -p "$AIRPLAY_FIFO" ]; then
    echo "Creating FIFO at $AIRPLAY_FIFO"
    rm -f "$AIRPLAY_FIFO"
    mkfifo "$AIRPLAY_FIFO" || true
    chown shairport-sync:shairport-sync "$AIRPLAY_FIFO"
  fi

  cat > "$AIRPLAY_CONF" <<EOF
general = {
  name = "$SYSTEM_NAME";
  output_backend = "pipe";
};

pipe = {
  name = "$AIRPLAY_FIFO";
};
EOF

  echo "shairport-sync config written to $AIRPLAY_CONF"

fi
