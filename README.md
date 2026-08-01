# Paradox Hypersonic Elixir 360 - Native Linux LCD Driver

Native Linux driver for the Paradox Gaming Hypersonic Elixir 360 AIO cooler LCD.
Replaces the Windows-only "DT Control" (`LCD-CS.exe`) app - no Wine needed.

Feeds CPU temp, GPU temp, and fan RPM to the LCD over raw HID.

## Reversed protocol

USB HID device `5131:2007`, 64-byte output report, no report ID:

| Byte | Field |
|------|-------|
| 0 | `0xaa` header |
| 1 | CPU temp (C) |
| 4 | fan RPM low byte |
| 5 | fan RPM high byte (16-bit little-endian) |
| 9 | GPU temp (C) |

LCD sleeps without periodic refresh, so the driver rewrites at 2 Hz (keepalive).

## Data sources

- CPU temp: `k10temp` (`/sys/class/hwmon/*/temp1_input`)
- GPU temp: `nvidia-smi`
- Fan RPM: first `fan*_input` hwmon (needs `nct6xxx` superio module; shows 0 if absent)

## Install

```sh
./install.sh
```

Adds the udev rule (needs sudo), installs the script + systemd user service,
and starts it. Auto-starts on boot.

## Manage

```sh
systemctl --user status aio-lcd
systemctl --user restart aio-lcd
systemctl --user stop aio-lcd
```

## Tested on

| Component | Detail |
|-----------|--------|
| Distro | Debian GNU/Linux 13 (trixie) |
| Kernel | `6.12.100+deb13-amd64` |
| CPU | AMD Ryzen 7 7700X (`k10temp`) |
| Motherboard | MSI MAG B650 TOMAHAWK WIFI (MS-7D75), `nct6687` |
| GPU | NVIDIA GeForce RTX 3070 (driver 550.163.01) |
| AIO | Paradox Hypersonic Elixir 360 (`5131:2007`) |

## Notes

- Device HID index can shift on replug; the driver auto-finds `5131:2007`.
- Fan RPM reads 0 on kernels without a superio (`nct6xxx`) module. Install
  `lm-sensors` and load the module - the driver picks up `fan*_input` automatically.
