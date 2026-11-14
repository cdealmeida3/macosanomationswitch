#!/bin/sh
# Packs build/Animation Switch.app into build/Animation-Switch.dmg, with an
# Applications shortcut to drag it onto, and writes its SHA-256 checksum to
# build/Animation-Switch.dmg.sha256. Run scripts/build-app.sh first.
# Uses only tools that ship with macOS.
set -eu
cd "$(dirname "$0")/.."

APP="build/Animation Switch.app"
DMG="build/Animation-Switch.dmg"
VERSION=$(tr -d '[:space:]' < VERSION)

if [ ! -d "$APP" ]; then
    echo "$APP is missing. Build it first with ./scripts/build-app.sh" >&2
    exit 1
fi

STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

# ditto keeps the code signature and extended attributes intact.
ditto "$APP" "$STAGING/Animation Switch.app"
ln -s /Applications "$STAGING/Applications"

rm -f "$DMG" "$DMG.sha256"

# hdiutil create sometimes fails on CI runners with "Resource busy" while the
# disk arbitration daemon is still settling, so retry a few times.
attempt=1
until hdiutil create \
        -volname "Animation Switch $VERSION" \
        -srcfolder "$STAGING" \
        -fs HFS+ \
        -format UDZO \
        -ov \
        "$DMG"; do
    if [ "$attempt" -ge 3 ]; then
        echo "hdiutil create failed $attempt times" >&2
        exit 1
    fi
    attempt=$((attempt + 1))
    echo "hdiutil create failed, retrying ($attempt of 3)" >&2
    sleep 5
done

# Only the file name goes in the checksum file, so that
# `shasum -a 256 -c Animation-Switch.dmg.sha256` works next to the download.
(cd build && shasum -a 256 Animation-Switch.dmg > Animation-Switch.dmg.sha256)

echo "Made $DMG (Animation Switch $VERSION)"
cat build/Animation-Switch.dmg.sha256
