# Paradox Hypersonic Elixir 360 — Linux LCD Driver

Native Linux feeder for the Paradox Gaming Hypersonic Elixir 360 AIO LCD.
Replaces the Windows-only **DT Control** (`LCD-CS.exe`) — no Wine.

Pushes **CPU temp**, **GPU temp**, and **fan/pump RPM** to the panel over raw USB HID (`5131:2007`) at ~2 Hz (keepalive; the LCD sleeps without refresh).

## Supported

| Feature | Backends |
|---------|----------|
| AIO LCD | Paradox Hypersonic Elixir 360 (`USB HID 5131:2007`) |
| CPU temp | AMD: `k10temp` (Tctl/Tccd1), `zenpower` (Tdie) · Intel: `coretemp` (Package id 0) |
| GPU temp | Selected at install · NVIDIA `nvidia-smi` · AMD `amdgpu` · Intel `i915` / `xe` |
| Fan / pump RPM | Selected at install · default hint `nct6687` `fan2_input` · else first nonzero (`auto`) |
| OS | Linux with `hidraw` + systemd user services |

## Requirements

- Python 3
- User in group that can open the device (udev rule uses `plugdev`)
- For NVIDIA GPU temp: proprietary driver + `nvidia-smi`
- For fan RPM on Nuvoton Super I/O boards: `nct6683` (see `nct6683-*.conf` in this repo; MSI often needs `options nct6683 force=1`)

## Install

```sh
./install.sh
```

Prompts for **GPU** and **fan/pump** source, writes `~/.config/aio-lcd.conf`, installs the udev rule (sudo), copies the script to `~/.local/bin`, enables the systemd user unit, and starts it.

Non-interactive:

```sh
GPU=nvidia:0 FAN=nct6687/fan2_input ./install.sh
```

Config values:

| Key | Examples |
|-----|----------|
| `GPU` | `auto` · `nvidia:0` · `amdgpu:temp1_input` · `i915:temp1_input` · `xe:temp1_input` |
| `FAN` | `auto` · `nct6687/fan2_input` |

Reconfigure: edit `~/.config/aio-lcd.conf`, then `systemctl --user restart aio-lcd`.

Optional — persist the Super I/O module (fan RPM):

```sh
sudo cp nct6683-modules-load.conf /etc/modules-load.d/nct6683.conf
sudo cp nct6683-modprobe.conf /etc/modprobe.d/nct6683.conf
sudo modprobe nct6683
```

## Manage

```sh
systemctl --user status aio-lcd
systemctl --user restart aio-lcd
systemctl --user stop aio-lcd
```

Sensor choice lives in `~/.config/aio-lcd.conf` (not the systemd unit). After editing, restart the service.

## Protocol

64-byte HID output report, **no report ID**:

| Byte | Field |
|------|-------|
| 0 | `0xaa` header |
| 1 | CPU temp (°C) |
| 4–5 | Fan RPM (uint16 LE) |
| 9 | GPU temp (°C) |

`hidraw` index can change on replug; the driver re-scans for `5131:2007`.

## Tested on

| Component | Detail |
|-----------|--------|
| Distro | Debian GNU/Linux 13 (trixie) |
| Kernel | `6.12.100+deb13-amd64` |
| CPU | AMD Ryzen 7 7700X (`k10temp`) |
| Motherboard | MSI MAG B650 TOMAHAWK WIFI (MS-7D75), `nct6687` |
| GPU | NVIDIA GeForce RTX 3070 (driver 550.163.01) |
| AIO | Paradox Hypersonic Elixir 360 (`5131:2007`) |

## License

MIT — see [LICENSE](LICENSE).
