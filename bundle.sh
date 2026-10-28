#!/bin/sh
# Builds a release binary and wraps it into Gazewell.app (menu bar only, ad-hoc signed).
# The version comes from the VERSION file. Usage: ./bundle.sh && open Gazewell.app
set -e
cd "$(dirname "$0")"
VERSION="$(tr -d '[:space:]' < VERSION)"
BUILD="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/Gazewell"
rm -rf Gazewell.app
mkdir -p Gazewell.app/Contents/MacOS
cp "$BIN" Gazewell.app/Contents/MacOS/Gazewell
cat > Gazewell.app/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Gazewell</string>
  <key>CFBundleIdentifier</key><string>local.gazewell</string>
  <key>CFBundleName</key><string>Gazewell</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$BUILD</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - Gazewell.app
echo "Built Gazewell.app $VERSION ($BUILD)"
