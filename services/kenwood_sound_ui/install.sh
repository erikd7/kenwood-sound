#!/bin/bash
set -e

ARCH=$1
CONFIG="/etc/kenwood-sound/device.json"
UI_ZIP_URL="https://github.com/erikd7/kenwood-sound-ui/archive/refs/heads/main.zip"
UI_INSTALL_DIR="/opt/kenwood-sound-ui"

# Early exit if UI not needed
if [ -f "$CONFIG" ]; then
  ROLE=$(jq -r '.role // "client"' "$CONFIG")
  if [[ "$ROLE" != "server" && "$ROLE" != "both" ]]; then
    echo "Kenwood Sound UI not needed for role: $ROLE"
    exit 0
  fi

  USE_UI=$(jq -r '.kenwood_sound_ui.enabled // false' "$CONFIG")
  if [ "$USE_UI" != "true" ]; then
    echo "kenwood_sound_ui not enabled in config"
    exit 0
  fi
fi

echo "Installing kenwood_sound_ui files"

if ! command -v wget >/dev/null 2>&1; then
  echo "Installing wget..."
  sudo apt install -y wget
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "Installing unzip..."
  sudo apt install -y unzip
fi

if command -v node >/dev/null 2>&1; then
  NODE_MAJOR=$(node -v | sed -E 's/^v([0-9]+).*/\1/')
else
  NODE_MAJOR=0
fi

if [ "$NODE_MAJOR" -lt 20 ]; then
  echo "Installing Node.js 20 (required for kenwood-sound-ui)..."
  sudo apt install -y ca-certificates curl gnupg
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
  sudo apt update
  sudo apt install -y nodejs
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading kenwood-sound-ui..."
wget -O "$TMP_DIR/kenwood-sound-ui.zip" "$UI_ZIP_URL"
unzip -q "$TMP_DIR/kenwood-sound-ui.zip" -d "$TMP_DIR"

if [ ! -d "$TMP_DIR/kenwood-sound-ui-main" ]; then
  echo "Downloaded archive missing expected folder kenwood-sound-ui-main"
  exit 1
fi

sudo rm -rf "$UI_INSTALL_DIR"
sudo mkdir -p "$UI_INSTALL_DIR"
sudo cp -r "$TMP_DIR/kenwood-sound-ui-main"/* "$UI_INSTALL_DIR"/

cd "$UI_INSTALL_DIR"

echo "Installing UI dependencies..."
if [ -f package-lock.json ]; then
  npm ci
else
  npm install
fi

if ! node -e "const p=require('./package.json'); process.exit(p?.scripts?.serve ? 0 : 1)"; then
  echo "kenwood-sound-ui package.json is missing scripts.serve"
  exit 1
fi

echo "kenwood_sound_ui downloaded and prepared at $UI_INSTALL_DIR"
