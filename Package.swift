// swift-tools-version: 6.2
import PackageDescription

// The UI-free core of Animation Switch (see docs/adr/0002). It must build and
// test on Linux as well as macOS, so it imports Foundation only.
let package = Package(
    name: "AnimationSwitch",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "AnimationSwitchCore", targets: ["AnimationSwitchCore"]),
    ],
    targets: [
        .target(name: "AnimationSwitchCore"),
        .testTarget(name: "AnimationSwitchCoreTests", dependencies: ["AnimationSwitchCore"]),
    ]
)
