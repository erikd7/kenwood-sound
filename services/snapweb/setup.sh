#!/bin/bash
set -e

CONFIG="$1"
ROLE="$2"

# Early exit if not server or if snapweb not enabled
if [[ "$ROLE" != "server" && "$ROLE" != "both" ]]; then
  exit 0
fi

USE_SNAPWEB=$(jq -r '.snapweb.enabled // false' "$CONFIG")
if [ "$USE_SNAPWEB" != "true" ]; then
  echo "Snapweb not enabled in config"
  exit 0
fi

echo "Configuring snapweb in snapserver"

SNAP_CONF="/etc/snapserver.conf"
DOC_ROOT="/usr/share/snapserver/snapweb"

if [ ! -f "$SNAP_CONF" ]; then
  echo "Error: snapserver.conf not found. Snapserver must be enabled when using snapweb."
  exit 1
fi

# Append http configuration section
cat >> "$SNAP_CONF" <<EOF

[http]
bindToAddress = 0.0.0.0
doc_root = $DOC_ROOT
EOF

echo "Snapweb configured in snapserver.conf"
