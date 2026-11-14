# Animation Switch

A macOS menu bar app that turns the system's UI animations off and puts them back exactly as they were.

It has one **Master Switch** and an **Animation Toggle** for each animation underneath. Flipping the switch off disables only the checked animations. Flipping it on restores each one to its **Original Value**, which is what the setting was before the app changed it. If you had customised a setting, you get your customisation back, not Apple's default. If the setting was never set, the app deletes the key again.

It is built for macOS 26 Tahoe and macOS 27 Golden Gate. It isn't in the Mac App Store and isn't signed with a developer ID, so you build it from source. See [docs/PLAN.md](docs/PLAN.md) for the full design and [GLOSSARY.md](GLOSSARY.md) for the terms.

## What it can switch off

| Group | Animation | Setting |
|---|---|---|
| Windows | Window open and close | `NSGlobalDomain NSAutomaticWindowAnimationsEnabled` |
| Windows | Sheets and window resizing | `NSGlobalDomain NSWindowResizeTime` |
| Windows | Full-screen toolbar slide | `NSGlobalDomain NSToolbarFullScreenAnimationDuration` |
| Windows | Versions browser | `NSGlobalDomain NSDocumentRevisionsWindowTransformAnimation` |
| Scrolling | Smooth scrolling (unchecked at first) | `NSGlobalDomain NSScrollAnimationEnabled` |
| Finder | Column view scrolling | `NSGlobalDomain NSBrowserColumnAnimationSpeedMultiplier` |
| Finder | Quick Look zoom | `NSGlobalDomain QLPanelAnimationDuration` |
| Finder | Finder animations | `com.apple.finder DisableAllAnimations` |
| Dock | Auto-hide delay | `com.apple.dock autohide-delay` |
| Dock | Auto-hide slide | `com.apple.dock autohide-time-modifier` |
| Dock | Bounce when opening apps | `com.apple.dock launchanim` |
| Dock | Minimize effect (Scale instead of Genie) | `com.apple.dock mineffect` |
| Mission Control | Mission Control transition | `com.apple.dock expose-animation-duration` |

A few things to know:

- The window settings only reach apps opened after the change. The app shows a note saying so, and it never relaunches your other apps.
- The app restarts the Dock or Finder itself, once per change, when a setting they read has changed.
- The auto-hide rows only matter if the Dock already hides automatically. The app never turns auto-hide on.
- The app doesn't control Reduce Motion, because macOS protects that setting. The menu shows whether it's on and opens the right System Settings pane.
- Spaces switching speed can't be changed. No setting for it exists.

## Build and run from source

You need a Mac with macOS 26 or later, Xcode 26 or later, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
git clone https://github.com/cdealmeida3/macosanomationswitch.git
cd macosanomationswitch
./scripts/build-app.sh
open "build/Animation Switch.app"
```

The script generates the Xcode project, builds a Release copy, ad-hoc signs it, and puts it at `build/Animation Switch.app`. Move it to `/Applications` if you want to keep it. The icon appears in the menu bar: sparkles while animations are on, a bolt while they're off. There is no Dock icon.

To work on the app in Xcode instead, run `cd App && xcodegen generate` and open `App/AnimationSwitch.xcodeproj`.

"Launch at login" is turned on the first time the app runs. If macOS asks you to approve it, the menu shows a warning that opens System Settings → General → Login Items.

## Getting your animations back

- Flip the Master Switch back on, or choose **Restore all and quit**. Either one puts back every setting the app changed.
- **Quit** leaves your settings as they are, so animations stay off after you quit.
- If you delete the app while animations are off, run it once more and choose **Restore all and quit** first.

## Tests

```sh
swift test
```

All the behaviour lives in the `AnimationSwitchCore` package, which has no UI and is tested against in-memory fakes on Linux and macOS. On macOS, `AnimationSwitchMac` adds integration tests that write to a throwaway preferences domain and never touch the real Dock, Finder or global settings. GitHub Actions runs both and builds the app on every pull request. A pull request merges only when all of it passes.

Whether each setting actually removes its animation can only be seen on a real Mac. That is what the [manual verification checklist](docs/manual-verification.md) is for.

## Project layout

- `Sources/AnimationSwitchCore`: the catalog, the engine, and the store and restarter interfaces with their fakes.
- `Sources/AnimationSwitchMac`: the real CFPreferences store, the Dock/Finder restarter, and the app-state store.
- `App/`: the SwiftUI menu bar app and its XcodeGen spec.
- `docs/`: the plan, architecture decisions, settings research and the manual checklist.
