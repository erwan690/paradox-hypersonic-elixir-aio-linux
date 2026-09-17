#!/bin/sh
# Build noarch aio-lcd-<version>.rpm into dist/.  Needs rpmbuild.
set -e
VERSION="${1:?usage: rpm.sh <version>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$(cd "$HERE/.." && pwd)"
OUT="$SRC/dist"
TOP="$(mktemp -d)"
trap 'rm -rf "$TOP"' EXIT

mkdir -p "$TOP/SPECS"
sed "s|@VERSION@|$VERSION|; s|@SRCDIR@|$SRC|" "$HERE/aio-lcd.spec.in" \
  > "$TOP/SPECS/aio-lcd.spec"

rpmbuild --define "_topdir $TOP" --define "dist %{nil}" -bb "$TOP/SPECS/aio-lcd.spec"

mkdir -p "$OUT"
cp "$TOP"/RPMS/noarch/*.rpm "$OUT/"
ls -l "$OUT"
