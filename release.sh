#!/bin/sh
# Cuts a release. Usage: ./release.sh <major|minor|patch>
# Bumps VERSION, stamps CHANGELOG.md's [Unreleased] notes with the new version and date, commits "Release vX.Y.Z" and
# tags it. Does not push: review, then `git push && git push --tags`.
set -e
cd "$(dirname "$0")"
[ -z "$(git status --porcelain)" ] || { echo "Working tree is not clean: commit or stash first." >&2; exit 1; }
cur="$(tr -d '[:space:]' < VERSION)"
IFS=. read -r MA MI PA <<EOV
$cur
EOV
case "$1" in
  major) MA=$((MA + 1)); MI=0; PA=0 ;;
  minor) MI=$((MI + 1)); PA=0 ;;
  patch) PA=$((PA + 1)) ;;
  *) echo "usage: $0 major|minor|patch" >&2; exit 1 ;;
esac
new="$MA.$MI.$PA"
grep -q '^## \[Unreleased\]' CHANGELOG.md || { echo "CHANGELOG.md has no [Unreleased] section." >&2; exit 1; }
awk -v v="$new" -v d="$(date +%Y-%m-%d)" '{ print } /^## \[Unreleased\]/ { print ""; print "## [" v "] - " d }' CHANGELOG.md > CHANGELOG.tmp
mv CHANGELOG.tmp CHANGELOG.md
echo "$new" > VERSION
git add VERSION CHANGELOG.md
git commit -q -m "Release v$new" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git tag -a "v$new" -m "Gazewell $new"
echo "Released v$new (was $cur). Push with: git push && git push --tags"
