#!/bin/sh
# Builds a release binary and wraps it into LookAway.app (menu bar only, ad-hoc signed). Usage: ./bundle.sh && open LookAway.app
set -e
cd "$(dirname "$0")"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/LookAway"
rm -rf LookAway.app
mkdir -p LookAway.app/Contents/MacOS
cp "$BIN" LookAway.app/Contents/MacOS/LookAway
cat > LookAway.app/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>LookAway</string>
  <key>CFBundleIdentifier</key><string>local.lookaway</string>
  <key>CFBundleName</key><string>LookAway</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - LookAway.app
echo "Built LookAway.app"
