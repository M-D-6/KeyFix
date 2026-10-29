#!/usr/bin/env bash
set -euo pipefail

version="$1"
bundle="$2"
output="$3"

root="$(mktemp -d)"
mkdir -p "$root/DEBIAN" "$root/opt/keyfix" "$root/usr/bin" "$root/usr/share/applications" "$root/usr/share/icons/hicolor/512x512/apps"

cp -r "$bundle"/. "$root/opt/keyfix/"
ln -s /opt/keyfix/keyfix "$root/usr/bin/keyfix"
cp ci/linux/keyfix.desktop "$root/usr/share/applications/keyfix.desktop"
cp docs/logo.png "$root/usr/share/icons/hicolor/512x512/apps/keyfix.png"

cat > "$root/DEBIAN/control" <<CONTROL
Package: keyfix
Version: $version
Section: utils
Priority: optional
Architecture: amd64
Maintainer: KeyFix
Depends: libgtk-3-0, libxkbcommon0, libx11-6, libxi6, libxtst6, libayatana-appindicator3-1, libnotify4, xclip | xsel | wl-clipboard
Description: Fix text typed in the wrong keyboard layout
 Select text typed with the wrong keyboard language and press a shortcut to convert it between Persian and English layouts.
CONTROL

dpkg-deb --root-owner-group --build "$root" "$output"
