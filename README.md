# Kenwood Sound

Kenwood Sound is a repeatable, config-driven toolkit to build a multiroom audio system using Snapcast with several sources set up out of the box, including Plexamp, shairport-sync (AirPlay), and go-librespot (Spotify Connect). It targets Raspberry Pi devices (or similar Linux SBCs) and aims to be simple to deploy and manage.

I'm going to write the rest of this readme with the silly assumption that one person one day might read it.

## Quick Start

1. Set up your Raspberry Pi running Raspberry Pi OS Lite or similar and connect it to your local network
2. SSH into the pi
   `ssh <rpi username>@<rpi host>`
3. Clone the quick start script
   `wget -O quick-start.sh https://raw.githubusercontent.com/erikd7/kenwood-sound/refs/heads/main/quick-start.sh`
4. Run the quick start script
   `sudo sh quick-start.sh`
5. When prompted, enter your device config (see ## Configuration and refer to examples in `/config`)
6. Open the UI and enjoy
   `<IP of your server>:1780`

## Background

### Hardware

I set this up using a cluster of Raspberry Pi 4 Bs with [HifiBerry DACs](https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/). With some tweaking I'm sure it could run on other hardware.

### OS

My Raspberry Pis are running [Raspberry Pi OS Lite](https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-12-04/2025-12-04-raspios-trixie-arm64-lite.img.xz), which is lightweight GUI-less x64 Debian distro.

## Configuration

Device configuration is done in `config/device.json`. This file is merged with the default config (`config/default.device.json`) by the setup service and the service setup files (e.g. `services/snapserver/setup.sh`), and then finally and assembled into environment files and a config in `/etc/kenwood-sound`.

There are example configurations in `/config`.

### Config option reference

Follow this format when editing `config/device.json`. Only include keys you want to override — missing keys fall back to `default.device.json`.

Top-level options

- `role`: string — one of `server`, `client`, `both`.
  - `server`: run Snapserver and source services (Plexamp, librespot, shairport-sync).
  - `client`: run Snapclient to receive audio and play it locally.
  - `both`: run both server and client roles on the same device.
- `device_name`: string — physical/host name of the device (also set as system hostname).

`snapserver` object

- `name`: string — user-visible name of the audio system (e.g. "My Home Audio"). Used as the Snapserver hostname and as source names exposed to clients (i.e. this is what you will see in Plexamp, Spotify, AirPlay).
- `ports`: object — network ports for snapcast:
  - `audio` (default: `1704`)
  - `control` (default: `1705`)
  - `http` (default: `1780`)
- `codec`: string — `flac` or `pcm` (default `flac`).
- `sample_format`: string — `RATE:BITS:CHANNELS` (e.g. `44100:16:2` or `48000:16:2`). This sets snapserver global sampleformat.
- `buffer_ms`: integer — buffer size in milliseconds.
- `streams`: object — enable/disable sources (booleans):
  - `librespot`: enable Spotify source
  - `airplay`: enable AirPlay source
  - `plexamp`: enable Plexamp source
  - `host_audio`: enable local host audio capture

`librespot` object

- `stream_name`: string — name shown in Snapcast for the Spotify stream.
- `device_type`: string — `speaker` or `player` (in librespot config)
- `bitrate`: integer — Spotify bitrate (e.g. `320`)
- `initial_volume`: integer — 0–100

`airplay` object

- `stream_name`: string — name shown in Snapcast for AirPlay.

`plexamp` object

- `stream_name`: string — name shown in Snapcast for Plexamp audio.

`host_audio` object

- `stream_name`: string — name shown in Snapcast for host audio input.
- `device`: string — ALSA device string (e.g. `hw:CARD=1,DEV=0` or `hw:Loopback,1,0`). Use `aplay -l` to list devices.
- `sample_format`: string — sample format for this source (`RATE:BITS:CHANNELS`).

`snapclient` object

- `server_host`: string — hostname/IP of the Snapserver for clients (default: `localhost`).
- `server_port`: integer — snapcast audio port (default: `1704`).
- `output_device`: string — ALSA PCM name to use (default: `snapclient_dac`).

Example snippet (more in `/config`):

```json
{
  "role": "both",
  "device_name": "Dining Room",
  "snapserver": {
    "name": "Home",
    "ports": {
      "audio": 1704,
      "control": 1705,
      "http": 1780
    },
    "codec": "flac",
    "sample_format": "48000:16:2",
    "buffer_ms": 100,
    "streams": {
      "librespot": true,
      "airplay": true,
      "plexamp": true,
      "host_audio": true
    }
  },
  "librespot": {
    "stream_name": "Spotify",
    "device_type": "speaker",
    "bitrate": 320,
    "initial_volume": 80,
    "volume_steps": 100
  },
  "airplay": {
    "stream_name": "AirPlay"
  },
  "plexamp": {
    "stream_name": "Plexamp"
  },
  "host_audio": {
    "stream_name": "Turntable",
    "device": "hw:CARD=2,DEV=0",
    "sample_format": "48000:16:2"
  },
  "snapclient": {
    "server_host": "localhost",
    "server_port": 1704,
    "output_device": "snapclient_dac"
  }
}
```

### Volume Control

I recommend initializing the software volume outside of Snapcast to make the Snapcast sliders work relative to your sound system. With the Snapcast sliders level for each room, set the underlying volume control using `alsamixer`, then F6 to your output soundcard, and use the up and down arrow keys to set the room's volume. Repeat for each room to get them to a similar initial level. Then use the Snapcast UI sliders to set volume whenever needed.

## Installation

You can also refer to [Quick Start](#quick-start)

### Download repository

Run these steps in your Debian terminal:

1. Clone the project
   `wget -O kenwood-sound.zip https://github.com/erikd7/kenwood-sound/archive/refs/heads/main.zip`
2. Unzip the source code
   `sudo unzip kenwood-sound.zip`
3. Create a new directory to run from
   `sudo mkdir /opt/kenwood-sound`
4. Move all the code to that directory
   `sudo mv -f kenwood-sound-main/* /opt/kenwood-sound`
5. Change to that directory
   `cd /opt/kenwood-sound`
6. Configure `config/device.json` (see #configuration)
7. Install
   `make install`
8. Run

## Snapcast

[Snapcast](https://github.com/snapcast/snapcast) is an open source audio synchronization platform. It consists of three components:

1. Snapserver: sends audio in multiple streams to any number of devices
2. Snapclient: receives audio stream from a snapserver
3. UI: Allows you to manage streams (group, mute, adjust volume, select stream, rename, etc.)

## Sources

Four sources have been set up out of the box.

### Plexamp

Runs [Plexamp headless](https://www.plex.tv/media-server-downloads/#plex-plexamp). You must have a Plex subscription/server.

#### Setup

The first run of Plexamp requires interactive inline configuration. Use the `quick-start.sh` script to set this smoothly.

### Spotify

Runs a Spotify Connect server via [go-librespot](https://github.com/devgianlu/go-librespot).

### AirPlay

Runs an AirPlay 2 server via [shairport-sync](https://github.com/mikebrady/shairport-sync).

### Host Audio

This just sends the audio from a host sound card to the Snapcast stream. This could be any audio source including external devices such as a TV, turntable, CD player, etc..

You need to set an input device in config to tell Snapcast which audio to send. Run `aplay -l` and use the card number from your device in config, like:

```
...
  "host_audio": {
    "stream_name": "My External Audio Device",
    "device": "hw:CARD=<my card number>,DEV=0",
    "sample_format": "41000:16:2"
  }
...
```

## Troubleshooting

## Additional Troubleshooting (concise checklist)

If the service behaves differently after a reboot or hardware change, check these quickly:

- Verify ALSA devices and cards:

```sh
aplay -l
cat /proc/asound/cards
ls -l /dev/snd
```

- View recent logs for relevant units:

```sh
journalctl -u snapclient -n 200 --no-pager
journalctl -u snapserver -n 200 --no-pager
journalctl -u kenwood-sound -n 200 --no-pager
```

- Kernel and driver messages (HATs/USB audio):

```sh
dmesg | egrep -i 'hifi|hifiberry|snd|i2s|bcm|audio'
```

- Check generated runtime files produced by `setup.service`:

```sh
sudo test -f /etc/kenwood-sound/kenwood-sound.env && echo env OK || echo env missing
ls -l /etc/snapserver.conf /etc/asound.conf || true
```

## Validation commands (one-liners)

- Confirm services and env created:

```sh
sudo test -f /etc/kenwood-sound/kenwood-sound.env && echo "env ok" || echo "env missing"
systemctl status kenwood-sound snapserver snapclient plexamp librespot shairport-sync --no-pager
```

- Check Snapserver UI (if running locally):

```sh
curl -fsS http://localhost:1780/ || echo "snapserver UI not responding"
```

## Contribution (short)

Contributions welcome — open a pull request with a short summary of the change. Small config examples, bug fixes, and hardware-specific notes (device-tree overlays, HAT quirks) are especially useful.

## Security notes (ports used)

Default ports used by the stack (configurable in `config/default.device.json`):

- `1704` — Snapcast audio
- `1705` — Snapcast control
- `1780` — Snapcast HTTP/UI

### Running services individually/directly

Refer to `services/start-services.sh` to see how they are called. For example:

- `sudo systemctl restart snapserver`
- `sudo systemctl stop snapserver`
- `sudo systemctl disable snapserver`
- `sudo systemctl enable snapserver`

### Inspecting service logs

Use `journalctl`, e.g. `journalctl -u snapserver.service -n 50 --no-pager
`

### Audio

- Check sound cards `aplay -l`
- Check sound aliases `aplay -L`
- Check sound cards as user `sudo -u snapserver aplay -l`
- Check sound config `cat /etc/asound.conf`
- Check boot config `cat /boot/firmware/config.txt`

### Sources

Refer to official documentation for Snapcast and sources. The [Snapcast documentation](https://github.com/snapcast/snapcast) is particularly helpful.
