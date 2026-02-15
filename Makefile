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

	# Overlay
	sudo cp -r overlay/etc/* /etc/

	# Scripts
	sudo cp config/device.json $(ETC_DIR)/device.json
	sudo cp services/apply-config/apply-config.sh $(BIN_DIR)/$(PROJECT_NAME)-apply-config
	sudo cp services/start-services.sh $(BIN_DIR)/$(PROJECT_NAME)-start
	sudo chmod +x $(BIN_DIR)/$(PROJECT_NAME)-*

	# Systemd service files
	sudo cp services/apply-config/apply-config.service $(SYSTEMD_DIR)/
	sudo cp services/librespot/librespot.service $(SYSTEMD_DIR)/
	sudo cp services/plexamp/plexamp.service $(SYSTEMD_DIR)/
	sudo cp services/snapserver/snapserver.service $(SYSTEMD_DIR)/
	sudo cp services/snapclient/snapclient.service $(SYSTEMD_DIR)/

	# Install deps
	sudo bash services/install.sh

	sudo systemctl daemon-reload
	@echo "Install complete."

	sudo systemctl restart apply-config.service
	@echo "Config applied."

enable:
	sudo systemctl enable apply-config.service
	sudo systemctl enable plexamp.service
	sudo systemctl enable librespot.service
	sudo systemctl enable snapserver.service
	sudo systemctl enable snapclient.service

disable:
	sudo systemctl disable apply-config.service || true
	sudo systemctl disable plexamp.service || true
	sudo systemctl disable librespot.service || true
	sudo systemctl disable snapserver.service || true
	sudo systemctl disable snapclient.service || true

uninstall:
	@echo "Uninstalling..."
	sudo systemctl disable apply-config.service || true
	sudo systemctl disable plexamp.service || true
	sudo systemctl disable librespot.service || true
	sudo systemctl disable snapserver.service || true
	sudo systemctl disable snapclient.service || true

	sudo rm -f $(SYSTEMD_DIR)/apply-config.service
	sudo rm -f $(SYSTEMD_DIR)/plexamp.service
	sudo rm -f $(SYSTEMD_DIR)/librespot.service
	sudo rm -f $(SYSTEMD_DIR)/snapserver.service
	sudo rm -f $(SYSTEMD_DIR)/snapclient.service

	sudo rm -f $(BIN_DIR)/$(PROJECT_NAME)-apply-config
	sudo rm -f $(BIN_DIR)/$(PROJECT_NAME)-start

	sudo systemctl daemon-reload
	@echo "Uninstall complete."

reinstall: uninstall install enable

status:
	systemctl status apply-config || true
	systemctl status snapserver || true
	systemctl status snapclient || true
	systemctl status plexamp || true
	systemctl status librespot || true
