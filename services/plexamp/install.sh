#!/bin/bash
set -e

ARCH=$(uname -m)

NODE_VERSION_FOR_PLEXAMP="20.9.0"
NODE_INSTALL_DIR="/opt/node"
NODE_BIN="$NODE_INSTALL_DIR/bin/node"

PLEXAMP_INSTALL_DIR="/usr/local/bin/plexamp"
PLEXAMP_VERSION_FILE="$PLEXAMP_INSTALL_DIR/.version"

if [[ "$USE_PLEXAMP" == "false" ]]; then
  echo "Plexamp is disabled, skipping installation..."
  exit 0
fi

if [[ "$ARCH" == "aarch64" ]]; then
    NODE_ARCH="arm64"
    PLEX_ARCH="arm64"
elif [[ "$ARCH" == "armv7l" ]]; then
    NODE_ARCH="armv7l"
    PLEX_ARCH="armhf"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Install Node
if [ -x "$NODE_BIN" ]; then
    INSTALLED_VERSION=$($NODE_BIN -v | sed 's/v//')
    if [ "$INSTALLED_VERSION" == "$NODE_VERSION_FOR_PLEXAMP" ]; then
        echo "Node $NODE_VERSION_FOR_PLEXAMP already installed."
    else
        echo "Different Node version detected ($INSTALLED_VERSION). Reinstalling..."
        sudo rm -rf "$NODE_INSTALL_DIR"
    fi
fi

if [ ! -x "$NODE_BIN" ]; then
    echo "Installing Node $NODE_VERSION_FOR_PLEXAMP..."
    sudo mkdir -p "$NODE_INSTALL_DIR"
    cd /tmp

    wget https://nodejs.org/dist/v${NODE_VERSION_FOR_PLEXAMP}/node-v${NODE_VERSION_FOR_PLEXAMP}-linux-${NODE_ARCH}.tar.xz -O node.tar.xz
    sudo tar -xf node.tar.xz -C "$NODE_INSTALL_DIR" --strip-components=1
    rm node.tar.xz
fi

echo "Node version: $($NODE_BIN -v)"

# Get Latest Plexamp Version
VERSION_INFO=$(curl -s https://plexamp.plex.tv/headless/version.json)
LATEST_VERSION_NUMBER=$(echo "$VERSION_INFO" | jq -r '.latestVersion')
LATEST_VERSION_URL=$(echo "$VERSION_INFO" | jq -r '.updateUrl')

echo "Latest Plexamp version: $LATEST_VERSION_NUMBER"

# Install Plexamp
INSTALL_PLEXAMP=false

if [ -f "$PLEXAMP_VERSION_FILE" ]; then
    INSTALLED_PLEX_VERSION=$(cat "$PLEXAMP_VERSION_FILE")
    if [ "$INSTALLED_PLEX_VERSION" == "$LATEST_VERSION_NUMBER" ]; then
        echo "Plexamp $LATEST_VERSION_NUMBER already installed."
    else
        echo "Updating Plexamp from $INSTALLED_PLEX_VERSION to $LATEST_VERSION_NUMBER"
        INSTALL_PLEXAMP=true
    fi
else
    INSTALL_PLEXAMP=true
fi

if [ "$INSTALL_PLEXAMP" = true ]; then
    echo "Installing Plexamp $LATEST_VERSION_NUMBER..."
    sudo rm -rf "$PLEXAMP_INSTALL_DIR"
    sudo mkdir -p "$PLEXAMP_INSTALL_DIR"

    cd /tmp
    wget "$LATEST_VERSION_URL" -O plexamp.tar.bz2
    sudo tar -xjf plexamp.tar.bz2 -C "$PLEXAMP_INSTALL_DIR" --strip-components=1
    sudo rm plexamp.tar.bz2

    echo "$LATEST_VERSION_NUMBER" | sudo tee "$PLEXAMP_VERSION_FILE" > /dev/null
fi

# Set up Plexamp user and directories
sudo useradd -r -s /usr/sbin/nologin plexamp 2>/dev/null || true
sudo mkdir -p /var/lib/plexamp/.config  
sudo mkdir -p /var/lib/plexamp/.local/share/Plexamp
sudo chown -R plexamp:plexamp /var/lib/plexamp

# Set up sink to pipe audio to
sudo modprobe snd-aloop # Create loopback device
echo "snd-aloop" | sudo tee /etc/modules-load.d/snd-aloop.conf
sudo usermod -aG audio plexamp # Add plexamp user to audio group to access loopback device

echo "Plexamp installed successfully"