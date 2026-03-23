#!/bin/bash
set -e

CONFIG="$1"
ROLE="$2"

# Early exit if not server or if kenwood_sound_ui not enabled
if [[ "$ROLE" != "server" && "$ROLE" != "both" ]]; then
  exit 0
fi

USE_UI=$(jq -r '.kenwood_sound_ui.enabled // false' "$CONFIG")
UI_DIR="/opt/kenwood-sound-ui"
HTTP_PORT=$(jq -r '.kenwood_sound_ui.ports.http // 80' "$CONFIG")
ENV_FILE="/etc/kenwood-sound/kenwood-sound-ui.env"

if [ "$USE_UI" != "true" ]; then
  echo "kenwood_sound_ui not enabled in config"
  sudo rm -f "$ENV_FILE"
  exit 0
fi

echo "Configuring kenwood_sound_ui service"

if [ ! -d "$UI_DIR" ]; then
  echo "Error: $UI_DIR not found. kenwood_sound_ui must be installed when enabled."
  exit 1
fi

# Write runtime environment for ui.service (npm run serve)
sudo mkdir -p /etc/kenwood-sound
cat <<EOF | sudo tee "$ENV_FILE" >/dev/null
KENWOOD_SOUND_UI_PORT="$HTTP_PORT"
KENWOOD_SOUND_UI_HOST="0.0.0.0"
KENWOOD_SOUND_UI_DIR="$UI_DIR"
EOF

echo "kenwood_sound_ui configured (port=$HTTP_PORT, dir=$UI_DIR)"
