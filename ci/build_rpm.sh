#!/usr/bin/env bash
set -euo pipefail

version="$1"
bundle="$(realpath "$2")"
output="$3"

top="$(mktemp -d)"
mkdir -p "$top"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

cat > "$top/SPECS/keyfix.spec" <<SPEC
%global debug_package %{nil}
%global __os_install_post %{nil}
AutoReqProv: no

Name: keyfix
Version: $version
Release: 1
Summary: Fix text typed in the wrong keyboard layout
License: GPL-3.0-only
BuildArch: x86_64
Requires: gtk3, libxkbcommon, libX11, libXi, libXtst, libayatana-appindicator-gtk3, libnotify, xorg-x11-xkb-utils, (xclip or xsel or wl-clipboard)

%description
Select text typed with the wrong keyboard language and press a shortcut to convert it between Persian and English layouts.

%install
mkdir -p %{buildroot}/opt/keyfix %{buildroot}/usr/bin %{buildroot}/usr/share/applications %{buildroot}/usr/share/icons/hicolor/512x512/apps
cp -r $bundle/. %{buildroot}/opt/keyfix/
ln -s /opt/keyfix/keyfix %{buildroot}/usr/bin/keyfix
cp $PWD/ci/linux/keyfix.desktop %{buildroot}/usr/share/applications/keyfix.desktop
cp $PWD/assets/icons/keyfix.png %{buildroot}/usr/share/icons/hicolor/512x512/apps/keyfix.png

%files
/opt/keyfix
/usr/bin/keyfix
/usr/share/applications/keyfix.desktop
/usr/share/icons/hicolor/512x512/apps/keyfix.png
SPEC

rpmbuild --define "_topdir $top" -bb "$top/SPECS/keyfix.spec"
cp "$top"/RPMS/x86_64/*.rpm "$output"
