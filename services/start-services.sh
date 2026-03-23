#!/bin/bash
set -euo pipefail

echo "Starting services for role: ${ROLE-}"

systemctl disable snapserver.service || true
systemctl disable snapclient.service || true
systemctl disable librespot.service || true
systemctl disable shairport-sync.service || true
systemctl disable plexamp.service || true
systemctl disable ui.service || true

case "$ROLE" in
  server)
    systemctl enable plexamp
    systemctl restart plexamp
    systemctl enable librespot
    systemctl restart librespot
    systemctl enable shairport-sync
    systemctl restart shairport-sync
    systemctl enable snapserver
    systemctl restart snapserver
    systemctl enable ui
    systemctl restart ui
    ;;
  client)
    systemctl enable snapclient
    systemctl restart snapclient
    ;;
  both)
    systemctl enable plexamp
    systemctl restart plexamp
    systemctl enable librespot
    systemctl restart librespot
    systemctl enable shairport-sync
    systemctl restart shairport-sync
    systemctl enable snapserver
    systemctl restart snapserver
    systemctl enable ui
    systemctl restart ui
    systemctl enable snapclient
    systemctl restart snapclient
    ;;
esac
