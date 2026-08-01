#!/bin/sh
# Install Paradox AIO LCD native driver
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[1/4] udev rule (needs sudo)"
sudo cp "$DIR/99-aio-paradox.rules" /etc/udev/rules.d/99-aio-paradox.rules
sudo udevadm control --reload-rules
sudo udevadm trigger -c add -s hidraw

echo "[2/4] driver script"
mkdir -p "$HOME/.local/bin"
cp "$DIR/aio-lcd.py" "$HOME/.local/bin/aio-lcd.py"
chmod +x "$HOME/.local/bin/aio-lcd.py"

echo "[3/4] systemd user service"
mkdir -p "$HOME/.config/systemd/user"
cp "$DIR/aio-lcd.service" "$HOME/.config/systemd/user/aio-lcd.service"
systemctl --user daemon-reload

echo "[4/4] enable + start"
systemctl --user enable --now aio-lcd.service
systemctl --user is-active aio-lcd.service

echo "done. LCD should show CPU/GPU temp."
