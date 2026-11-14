#!/bin/sh
# Builds "Animation Switch.app" from source, ad-hoc signed and universal
# (arm64 and x86_64), into ./build.
# Needs Xcode 26 or later and XcodeGen (brew install xcodegen).
#
# The version comes from the VERSION file at the repo root, the only place it
# is written. The build number comes from BUILD_NUMBER (CI passes the GitHub
# Actions run number) and defaults to 1 for local builds.
set -eu
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "XcodeGen is missing. Install it with: brew install xcodegen" >&2
    exit 1
fi

VERSION=$(tr -d '[:space:]' < VERSION)
BUILD_NUMBER=${BUILD_NUMBER:-1}

(cd App && xcodegen generate --quiet)
xcodebuild \
    -project App/AnimationSwitch.xcodeproj \
    -scheme AnimationSwitch \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath build/DerivedData \
    -quiet \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    build

rm -rf "build/Animation Switch.app"
ditto "build/DerivedData/Build/Products/Release/Animation Switch.app" "build/Animation Switch.app"
echo "Built build/Animation Switch.app $VERSION ($BUILD_NUMBER)"
