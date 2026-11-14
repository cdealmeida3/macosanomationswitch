// swift-tools-version: 6.2
import PackageDescription

// The UI-free core of Animation Switch (see docs/adr/0002). It must build and
// test on Linux as well as macOS, so it imports Foundation only.
//
// AnimationSwitchMac holds the adapters that talk to the real system
// (CFPreferences, Dock and Finder). Its sources are wrapped in `#if os(macOS)`
// so the package still builds on Linux, where the target is empty.
let package = Package(
    name: "AnimationSwitch",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "AnimationSwitchCore", targets: ["AnimationSwitchCore"]),
        .library(name: "AnimationSwitchMac", targets: ["AnimationSwitchMac"]),
    ],
    targets: [
        .target(name: "AnimationSwitchCore"),
        .target(
            name: "AnimationSwitchMac",
            dependencies: ["AnimationSwitchCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "AnimationSwitchCoreTests", dependencies: ["AnimationSwitchCore"]),
        .testTarget(
            name: "AnimationSwitchMacTests",
            dependencies: ["AnimationSwitchMac", "AnimationSwitchCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
