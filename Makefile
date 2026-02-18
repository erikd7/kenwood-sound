ETC_DIR=/etc/kenwood-sound
BIN_DIR=/usr/local/bin
SYSTEMD_DIR=/etc/systemd/system

PROJECT_NAME=kenwood-sound

.PHONY: install uninstall reinstall enable disable status

install:
	@echo "Installing $(PROJECT_NAME)..."

	sudo apt update

	# Config dir
	sudo mkdir -p $(ETC_DIR)

	# Copy config first so install scripts can check device.json
	sudo cp config/device.json $(ETC_DIR)/device.json
	sudo cp config/default.device.json $(ETC_DIR)/default.device.json

	# Overlay
	sudo cp -r overlay/etc/* /etc/ || true

	# Setup scripts
	sudo cp services/setup/setup.sh $(BIN_DIR)/$(PROJECT_NAME)-setup
	sudo cp services/snapserver/setup.sh $(BIN_DIR)/$(PROJECT_NAME)-snapserver-setup
	sudo cp services/librespot/setup.sh $(BIN_DIR)/$(PROJECT_NAME)-librespot-setup
	sudo cp services/shairport-sync/setup.sh $(BIN_DIR)/$(PROJECT_NAME)-shairport-setup
	sudo cp services/plexamp/setup.sh $(BIN_DIR)/$(PROJECT_NAME)-plexamp-setup
	sudo cp services/start-services.sh $(BIN_DIR)/$(PROJECT_NAME)-start
	sudo chmod +x $(BIN_DIR)/$(PROJECT_NAME)-*

	# Systemd service files
	sudo cp services/setup/setup.service $(SYSTEMD_DIR)/
	sudo cp services/librespot/librespot.service $(SYSTEMD_DIR)/
	sudo cp services/plexamp/plexamp.service $(SYSTEMD_DIR)/
	sudo cp services/snapserver/snapserver.service $(SYSTEMD_DIR)/
	sudo cp services/snapclient/snapclient.service $(SYSTEMD_DIR)/
	sudo cp services/kenwood-sound.service $(SYSTEMD_DIR)/
	sudo cp services/shairport-sync/shairport-sync.service $(SYSTEMD_DIR)/

	# Install deps (install scripts check device.json and exit early if not needed)
	sudo bash services/install.sh

	sudo systemctl daemon-reload
	@echo "Install complete."

	sudo systemctl restart setup.service
	@echo "Config applied."

enable:
	sudo systemctl enable setup.service
	sudo systemctl enable plexamp.service
	sudo systemctl enable librespot.service
	sudo systemctl enable snapserver.service
	sudo systemctl enable snapclient.service
	sudo systemctl enable shairport-sync.service
	sudo systemctl enable kenwood-sound.service

disable:
	sudo systemctl disable setup.service || true
	sudo systemctl disable plexamp.service || true
	sudo systemctl disable librespot.service || true
	sudo systemctl disable snapserver.service || true
	sudo systemctl disable snapclient.service || true
	sudo systemctl disable shairport-sync.service || true
	sudo systemctl disable kenwood-sound.service || true

uninstall:
	@echo "Uninstalling..."
	sudo systemctl disable setup.service || true
	sudo systemctl disable plexamp.service || true
	sudo systemctl disable librespot.service || true
	sudo systemctl disable snapserver.service || true
	sudo systemctl disable snapclient.service || true
	sudo systemctl disable shairport-sync.service || true

	sudo rm -f $(SYSTEMD_DIR)/setup.service
	sudo rm -f $(SYSTEMD_DIR)/plexamp.service
	sudo rm -f $(SYSTEMD_DIR)/librespot.service
	sudo rm -f $(SYSTEMD_DIR)/snapserver.service
	sudo rm -f $(SYSTEMD_DIR)/snapclient.service
	sudo rm -f $(SYSTEMD_DIR)/shairport-sync.service
	sudo rm -f $(SYSTEMD_DIR)/kenwood-sound.service

	sudo rm -f $(BIN_DIR)/$(PROJECT_NAME)-setup
	sudo rm -f $(BIN_DIR)/$(PROJECT_NAME)-snapserver-setup
	sudo rm -f $(BIN_DIR)/$(PROJECT_NAME)-librespot-setup
	sudo rm -f $(BIN_DIR)/$(PROJECT_NAME)-shairport-setup
	sudo rm -f $(BIN_DIR)/$(PROJECT_NAME)-plexamp-setup
	sudo rm -f $(BIN_DIR)/$(PROJECT_NAME)-start

	sudo systemctl daemon-reload
	@echo "Uninstall complete."

reinstall: uninstall install enable

status:
	systemctl status setup || true
	systemctl status snapserver || true
	systemctl status snapclient || true
	systemctl status plexamp || true
	systemctl status librespot || true
	systemctl status shairport-sync || true
	systemctl status kenwood-sound || true
