#!/bin/sh
# Builds LookAway.app and wraps it in LookAway.dmg (drag-to-Applications layout). Usage: ./dmg.sh
set -e
cd "$(dirname "$0")"
./bundle.sh
STAGE="$(mktemp -d)"
cp -R LookAway.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f LookAway.dmg
hdiutil create -volname LookAway -srcfolder "$STAGE" -ov -format UDZO LookAway.dmg >/dev/null
rm -rf "$STAGE"
echo "Built LookAway.dmg"
