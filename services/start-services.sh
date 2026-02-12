#!/bin/bash

echo "Starting services for node type $ROLE"

systemctl disable snapserver.service || true
systemctl disable snapclient.service || true
systemctl disable librespot.service || true

case "$ROLE" in
  server)
    systemctl enable snapserver
    systemctl enable librespot
    ;;
  client)
    systemctl enable snapclient
    ;;
  both)
    systemctl enable snapserver
    systemctl enable librespot
    systemctl enable snapclient
    ;;
esac
