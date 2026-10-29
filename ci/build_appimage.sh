#!/usr/bin/env bash
set -euo pipefail

bundle="$(realpath "$1")"
output="$2"

dir="$(mktemp -d)/KeyFix.AppDir"
mkdir -p "$dir/usr/bin"
cp -r "$bundle"/. "$dir/usr/bin/"

cp docs/logo.png "$dir/keyfix.png"
cp ci/linux/keyfix.desktop "$dir/keyfix.desktop"
sed -i 's#^Exec=.*#Exec=keyfix#' "$dir/keyfix.desktop"

cat > "$dir/AppRun" <<'RUN'
#!/bin/sh
here="$(dirname "$(readlink -f "$0")")"
exec "$here/usr/bin/keyfix" "$@"
RUN
chmod +x "$dir/AppRun"

tool="$(mktemp -d)/appimagetool"
curl -fsSL -o "$tool" https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x "$tool"

ARCH=x86_64 "$tool" --appimage-extract-and-run "$dir" "$output"
