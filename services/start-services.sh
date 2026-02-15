#!/bin/bash

echo "Starting services for node type $ROLE"

CONFIG="/etc/kenwood-sound/device.json"

systemctl disable snapserver.service || true
systemctl disable snapclient.service || true
systemctl disable librespot.service || true

case "$ROLE" in
  server)
    systemctl enable snapserver
    systemctl restart snapserver
    systemctl enable librespot
    systemctl restart librespot
    ;;
  client)
    systemctl enable snapclient
    systemctl restart snapclient
    ;;
  both)
    systemctl enable snapserver
    systemctl restart snapserver
    systemctl enable librespot
    systemctl restart librespot
    systemctl enable snapclient
    systemctl restart snapclient
    ;;
esac
