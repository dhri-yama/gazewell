#!/bin/sh
# Builds Gazewell.app and wraps it in Gazewell-<version>.dmg (drag-to-Applications layout). Usage: ./dmg.sh
set -e
cd "$(dirname "$0")"
VERSION="$(tr -d '[:space:]' < VERSION)"
./bundle.sh
STAGE="$(mktemp -d)"
cp -R Gazewell.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "Gazewell-$VERSION.dmg"
hdiutil create -volname Gazewell -srcfolder "$STAGE" -ov -format UDZO "Gazewell-$VERSION.dmg" >/dev/null
rm -rf "$STAGE"
echo "Built Gazewell-$VERSION.dmg"
