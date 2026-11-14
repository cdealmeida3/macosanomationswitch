#!/bin/sh
# Builds "Animation Switch.app" from source, ad-hoc signed, into ./build.
# Needs Xcode 26 or later and XcodeGen (brew install xcodegen).
set -eu
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "XcodeGen is missing. Install it with: brew install xcodegen" >&2
    exit 1
fi

(cd App && xcodegen generate --quiet)
xcodebuild \
    -project App/AnimationSwitch.xcodeproj \
    -scheme AnimationSwitch \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    -quiet \
    build

rm -rf "build/Animation Switch.app"
cp -R "build/DerivedData/Build/Products/Release/Animation Switch.app" build/
echo "Built build/Animation Switch.app"
