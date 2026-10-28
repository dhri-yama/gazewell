#!/bin/sh
# Publishes the current VERSION: builds the DMG and creates a GitHub release with that version's changelog notes and the DMG
# attached. Prints the sha256 for the Homebrew cask. Run after ./release.sh and `git push && git push --tags`.
set -e
cd "$(dirname "$0")"
V="$(tr -d '[:space:]' < VERSION)"
git rev-parse "v$V" >/dev/null 2>&1 || { echo "Tag v$V does not exist: run ./release.sh first." >&2; exit 1; }
[ "$(git rev-parse "v$V^{commit}")" = "$(git rev-parse HEAD)" ] || { echo "HEAD is not at tag v$V: build releases from the tagged commit." >&2; exit 1; }
./dmg.sh
NOTES="$(mktemp)"
awk -v v="$V" '/^## \[/ { p = index($0, "[" v "]") > 0; next } p' CHANGELOG.md > "$NOTES"
cat >> "$NOTES" <<EOF

### Install
- Homebrew: \`brew install --cask dhri-yama/tap/gazewell\`
- Or open the DMG and drag Gazewell to Applications. The app is not notarized: on first launch go to System Settings, Privacy & Security, and choose Open Anyway.
EOF
gh release create "v$V" "Gazewell-$V.dmg" --title "Gazewell $V" --notes-file "$NOTES"
rm -f "$NOTES"
echo "sha256 $(shasum -a 256 "Gazewell-$V.dmg" | cut -d' ' -f1)  (update version and sha256 in the Homebrew cask)"
