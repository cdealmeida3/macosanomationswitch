#!/bin/sh
# Checks build/Animation-Switch.dmg the way a person will use it: the image is
# sound, it holds only the app and an Applications shortcut, and the app inside
# is validly signed, universal and of the version in VERSION.
# CI runs it on every pull request and the release workflow before publishing.
# Exits non-zero on any failure. Never skip or soften a check to get a green run.
set -eu
cd "$(dirname "$0")/.."

DMG="${1:-build/Animation-Switch.dmg}"
EXPECTED_VERSION=$(tr -d '[:space:]' < VERSION)
failures=0

fail() {
    echo "FAIL: $*" >&2
    failures=$((failures + 1))
}

pass() {
    echo "ok: $*"
}

[ -f "$DMG" ] || { echo "FAIL: $DMG is missing" >&2; exit 1; }

hdiutil verify "$DMG"
pass "hdiutil verify"

if [ -f "$DMG.sha256" ]; then
    if (cd "$(dirname "$DMG")" && shasum -a 256 -c "$(basename "$DMG").sha256"); then
        pass "checksum file matches"
    else
        fail "checksum file does not match $DMG"
    fi
fi

MOUNT=$(mktemp -d)
detach() {
    hdiutil detach "$MOUNT" -quiet >/dev/null 2>&1 \
        || hdiutil detach "$MOUNT" -force -quiet >/dev/null 2>&1 \
        || true
    rmdir "$MOUNT" 2>/dev/null || true
}
trap detach EXIT

hdiutil attach "$DMG" -nobrowse -readonly -noautoopen -mountpoint "$MOUNT" >/dev/null
pass "mounted read-only at $MOUNT"

# Exactly the app and the Applications shortcut, ignoring hidden
# file-system entries such as .fseventsd.
# shellcheck disable=SC2012 # the names are known and plain
entries=$(cd "$MOUNT" && ls -1 | sort | tr '\n' '|')
if [ "$entries" = "Animation Switch.app|Applications|" ]; then
    pass "image holds Animation Switch.app and Applications"
else
    fail "unexpected image contents: $entries"
fi

if [ -L "$MOUNT/Applications" ] && [ "$(readlink "$MOUNT/Applications")" = "/Applications" ]; then
    pass "Applications is a symlink to /Applications"
else
    fail "Applications is not a symlink to /Applications"
fi

APP="$MOUNT/Animation Switch.app"
BIN="$APP/Contents/MacOS/Animation Switch"
PLIST="$APP/Contents/Info.plist"

if codesign --verify --deep --strict --verbose=2 "$APP"; then
    pass "codesign --verify --deep --strict"
else
    fail "the app's signature is broken (people would see \"is damaged and can't be opened\")"
fi

archs=$(lipo -archs "$BIN" 2>/dev/null || echo "")
case " $archs " in
    *" arm64 "*) pass "has arm64" ;;
    *) fail "arm64 missing (lipo says: $archs)" ;;
esac
case " $archs " in
    *" x86_64 "*) pass "has x86_64" ;;
    *) fail "x86_64 missing (lipo says: $archs)" ;;
esac

version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST" 2>/dev/null || echo "")
if [ "$version" = "$EXPECTED_VERSION" ]; then
    pass "CFBundleShortVersionString is $version"
else
    fail "CFBundleShortVersionString is '$version', VERSION says '$EXPECTED_VERSION'"
fi

build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST" 2>/dev/null || echo "")
if [ -n "$build" ]; then
    pass "CFBundleVersion is $build"
else
    fail "CFBundleVersion is empty"
fi

if [ "$(/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$PLIST" 2>/dev/null)" = "true" ]; then
    pass "LSUIElement is true (menu bar only)"
else
    fail "LSUIElement is not true"
fi

volname=$(diskutil info "$MOUNT" 2>/dev/null | sed -n 's/^ *Volume Name: *//p')
if [ "$volname" = "Animation Switch $EXPECTED_VERSION" ]; then
    pass "volume name is $volname"
else
    fail "volume name is '$volname', expected 'Animation Switch $EXPECTED_VERSION'"
fi

if [ "$failures" -ne 0 ]; then
    echo "$failures check(s) failed for $DMG" >&2
    exit 1
fi
echo "All checks passed for $DMG"
