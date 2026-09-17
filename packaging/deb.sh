#!/bin/sh
# Build aio-lcd_<version>_all.deb into dist/.  Needs dpkg-deb.
set -e
VERSION="${1:?usage: deb.sh <version>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$(cd "$HERE/.." && pwd)"
OUT="$SRC/dist"
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

sh "$HERE/stage.sh" "$ROOT"
# Debian policy puts the licence at /usr/share/doc/<pkg>/copyright, not /usr/share/licenses
mv "$ROOT/usr/share/licenses/aio-lcd/LICENSE" "$ROOT/usr/share/doc/aio-lcd/copyright"
rm -rf "$ROOT/usr/share/licenses"

mkdir -p "$ROOT/DEBIAN"
cat > "$ROOT/DEBIAN/control" <<EOF
Package: aio-lcd
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: python3
Recommends: python3-gi, gir1.2-gtk-3.0, gir1.2-ayatanaappindicator3-0.1
Maintainer: erwan690 <noreply@github.com>
Homepage: https://github.com/erwan690/paradox-hypersonic-elixir-aio-linux
Description: Native Linux LCD feeder for Paradox Hypersonic Elixir 360 AIO
 Pushes CPU temp, GPU temp and fan/pump RPM to the AIO LCD panel over raw
 USB HID (5131:2007), replacing the Windows-only DT Control application.
 Ships a systemd user service and an optional GTK tray GUI.
EOF

cat > "$ROOT/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
udevadm control --reload-rules 2>/dev/null || true
udevadm trigger -c add -s hidraw 2>/dev/null || true
echo "aio-lcd: enable per user with: systemctl --user enable --now aio-lcd.service"
EOF
chmod 755 "$ROOT/DEBIAN/postinst"

cat > "$ROOT/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
udevadm control --reload-rules 2>/dev/null || true
EOF
chmod 755 "$ROOT/DEBIAN/postrm"

mkdir -p "$OUT"
dpkg-deb --root-owner-group --build "$ROOT" "$OUT/aio-lcd_${VERSION}_all.deb"
ls -l "$OUT"
