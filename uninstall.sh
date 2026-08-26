#!/bin/sh
# Uninstall Paradox AIO LCD native driver.  --purge also removes ~/.config/aio-lcd.conf
set -e
CFG="$HOME/.config/aio-lcd.conf"
PURGE=0
[ "$1" = "--purge" ] && PURGE=1

echo "[1/5] stop + disable service"
systemctl --user disable --now aio-lcd.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/aio-lcd.service"
systemctl --user daemon-reload
systemctl --user reset-failed aio-lcd.service 2>/dev/null || true

echo "[2/5] udev rule (needs sudo)"
# 99- is the stale name from installs before the uaccess fix
sudo rm -f /etc/udev/rules.d/60-aio-paradox.rules /etc/udev/rules.d/99-aio-paradox.rules
sudo udevadm control --reload-rules || true
sudo udevadm trigger -c add -s hidraw || true

echo "[3/5] driver + GUI"
rm -f "$HOME/.local/bin/aio-lcd.py" "$HOME/.local/bin/aio-lcd-gui.py"

echo "[4/5] desktop entry"
rm -f "$HOME/.local/share/applications/aio-lcd-gui.desktop"
command -v update-desktop-database >/dev/null 2>&1 \
  && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 \
  || true

echo "[5/5] config"
if [ "$PURGE" -eq 1 ]; then
    rm -f "$CFG"
    echo "removed $CFG"
else
    echo "kept $CFG  (--purge to remove)"
fi

echo ""
echo "done. LCD keeps its last frame until the AIO is power-cycled."
echo "note: nct6683 module files under /etc/modules-load.d and /etc/modprobe.d are left alone"
echo "      (other tools may rely on them) — remove by hand if you want them gone."
