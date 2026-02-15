#!/bin/bash
set -e

if [[ "$USE_LIBRESPOT" == "false" ]]; then
  echo "Librespot is disabled, skipping installation..."
  exit 0
fi

ARCH=$1  # receive from top-level script
echo "Librespot install running on $ARCH"

if [[ "$ARCH" == "aarch64" ]]; then
    LIBRESPOT_ARCH="arm64"
elif [[ "$ARCH" == "armv7l" ]]; then
    LIBRESPOT_ARCH="armv6_rpi"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Creating librespot user..."
sudo useradd -r -s /usr/sbin/nologin librespot || true
sudo mkdir -p /var/lib/librespot/.config/go-librespot
sudo chown -R librespot:librespot /var/lib/librespot/.config

TMPDIR=$(mktemp -d)
echo "Downloading go-librespot tarball for $LIBRESPOT_ARCH..."
curl -L "https://github.com/devgianlu/go-librespot/releases/download/v0.6.2/go-librespot_linux_$LIBRESPOT_ARCH.tar.gz" \
    -o "$TMPDIR/librespot.tar.gz"

echo "Extracting binary..."
tar -xzf "$TMPDIR/librespot.tar.gz" -C "$TMPDIR"

echo "Installing binary..."
sudo mv "$TMPDIR/go-librespot" /usr/local/bin/librespot
sudo chmod +x /usr/local/bin/librespot

rm -rf "$TMPDIR"

echo "Librespot installed successfully"