#!/bin/sh
# Stage the system-wide file layout into $1 (a package buildroot).
# Single owner of "where does each file go" — both deb.sh and the rpm spec call this.
set -e
ROOT="$1"
SRC="$(cd "$(dirname "$0")/.." && pwd)"
[ -n "$ROOT" ] || { echo "usage: stage.sh <buildroot>" >&2; exit 2; }

install -D -m 755 "$SRC/aio-lcd.py"          "$ROOT/usr/bin/aio-lcd"
install -D -m 755 "$SRC/aio-lcd-gui.py"      "$ROOT/usr/bin/aio-lcd-gui"
install -D -m 644 "$SRC/60-aio-paradox.rules" "$ROOT/usr/lib/udev/rules.d/60-aio-paradox.rules"
install -D -m 644 "$SRC/README.md"           "$ROOT/usr/share/doc/aio-lcd/README.md"
install -D -m 644 "$SRC/LICENSE"             "$ROOT/usr/share/licenses/aio-lcd/LICENSE"
install -D -m 644 "$SRC/nct6683-modprobe.conf"     "$ROOT/usr/share/doc/aio-lcd/nct6683-modprobe.conf"
install -D -m 644 "$SRC/nct6683-modules-load.conf" "$ROOT/usr/share/doc/aio-lcd/nct6683-modules-load.conf"

# Packaged unit runs the packaged binary, not the ~/.local/bin copy install.sh makes.
sed 's|^ExecStart=.*|ExecStart=/usr/bin/aio-lcd|' "$SRC/aio-lcd.service" \
  > "$ROOT/tmp-unit"
install -D -m 644 "$ROOT/tmp-unit" "$ROOT/usr/lib/systemd/user/aio-lcd.service"
rm -f "$ROOT/tmp-unit"

sed 's|^Exec=.*|Exec=aio-lcd-gui|; s|^TryExec=.*|TryExec=aio-lcd-gui|; s|^StartupWMClass=.*|StartupWMClass=aio-lcd-gui|' \
  "$SRC/aio-lcd-gui.desktop" > "$ROOT/tmp-desktop"
install -D -m 644 "$ROOT/tmp-desktop" "$ROOT/usr/share/applications/aio-lcd-gui.desktop"
rm -f "$ROOT/tmp-desktop"
