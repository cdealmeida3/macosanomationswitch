# Animation Switch

A macOS menu bar app that turns the system's UI animations off and puts them back exactly as they were.

It has one **Master Switch** and an **Animation Toggle** for each animation underneath. Flipping the switch off disables only the checked animations. Flipping it on restores each one to its **Original Value**, which is what the setting was before the app changed it. If you had customised a setting, you get your customisation back, not Apple's default. If the setting was never set, the app deletes the key again.

It is built for macOS 26 Tahoe and macOS 27 Golden Gate, on Apple Silicon and Intel Macs. It's free: [download the disk image](#download) or [build it from source](#build-and-run-from-source). It isn't in the Mac App Store and isn't notarized by Apple, so macOS asks you to allow it once (see [First launch](#first-launch)). See [docs/PLAN.md](docs/PLAN.md) for the full design and [GLOSSARY.md](GLOSSARY.md) for the terms.

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

## Download

**[Download Animation-Switch.dmg](https://github.com/cdealmeida3/macosanomationswitch/releases/latest/download/Animation-Switch.dmg)** (latest version, macOS 26 or later). Release notes and older versions are on the [releases page](https://github.com/cdealmeida3/macosanomationswitch/releases/latest).

1. Open `Animation-Switch.dmg`.
2. Drag **Animation Switch** onto the **Applications** shortcut next to it.
3. Open Animation Switch from Applications, and allow it once as described below.

Move the app to Applications **before** you open it for the first time. If you open it straight from the disk image or Downloads, macOS runs it from a hidden temporary copy, and Launch at login can end up pointing at the wrong copy.

The icon appears in the menu bar: sparkles while animations are on, a bolt while they're off. There is no Dock icon.

### First launch

The app is ad-hoc signed but not notarized, because notarizing needs a paid Apple Developer account. macOS therefore blocks the first launch of each downloaded version once:

1. Open Animation Switch from Applications. macOS says it could not verify that the app is free of malware. Click **Done**, not Move to Trash.
2. Open **System Settings → Privacy & Security**, scroll down to Security, and click **Open Anyway** next to the line about "Animation Switch". Enter your password.
3. Click **Open** in the dialog that follows. From then on the app opens normally.

Control-click → Open no longer skips this step since macOS 15. If you're comfortable with Terminal, this does the same thing:

```sh
xattr -dr com.apple.quarantine "/Applications/Animation Switch.app"
open "/Applications/Animation Switch.app"
```

If macOS ever says the app "is damaged and can't be opened", the download or the copy broke its signature. Download it again, and if that doesn't help, please open an issue: every release is checked for this before it's published.

### Updating

There is no auto-update. To update, choose **Quit** from the menu, download the new `Animation-Switch.dmg`, drag the app to Applications and choose **Replace**. Your settings and Original Values are kept.

Each new version needs **Open Anyway** once. Every build has a different ad-hoc signature, so macOS may also ask you to allow the login item again. The menu shows a warning when it does, and the warning opens Login Items settings.

### Checking the download

Each release also has `Animation-Switch.dmg.sha256`. Download it next to the disk image and run:

```sh
shasum -a 256 -c Animation-Switch.dmg.sha256
```

It prints `Animation-Switch.dmg: OK` when the file is intact.

## Build and run from source

You need a Mac with macOS 26 or later, Xcode 26 or later, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
git clone https://github.com/cdealmeida3/macosanomationswitch.git
cd macosanomationswitch
./scripts/build-app.sh
open "build/Animation Switch.app"
```

The script generates the Xcode project, builds a universal Release copy with the version from the `VERSION` file, ad-hoc signs it, and puts it at `build/Animation Switch.app`. To make the same disk image a release has, run `./scripts/make-dmg.sh` and then `./scripts/verify-dmg.sh`. Move it to `/Applications` if you want to keep it. The icon appears in the menu bar: sparkles while animations are on, a bolt while they're off. There is no Dock icon.

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

All the behaviour lives in the `AnimationSwitchCore` package, which has no UI and is tested against in-memory fakes on Linux and macOS. On macOS, `AnimationSwitchMac` adds integration tests that write to a throwaway preferences domain and never touch the real Dock, Finder or global settings. GitHub Actions runs both on every pull request, builds the app and its disk image, checks the image, and keeps it for 7 days as a workflow artifact named `Animation-Switch-dmg`. A pull request merges only when all of it passes.

Whether each setting actually removes its animation can only be seen on a real Mac. That is what the [manual verification checklist](docs/manual-verification.md) is for.

## Project layout

- `Sources/AnimationSwitchCore`: the catalog, the engine, and the store and restarter interfaces with their fakes.
- `Sources/AnimationSwitchMac`: the real CFPreferences store, the Dock/Finder restarter, and the app-state store.
- `App/`: the SwiftUI menu bar app and its XcodeGen spec.
- `scripts/`: building the app, making the disk image, and checking it.
- `docs/`: the plan, the release plan, architecture decisions, settings research and the manual checklist.

## Releasing a new version

To publish a new version, open a pull request that changes `VERSION`, for example from `1.0.0` to `1.1.0`. When it merges, the [release workflow](.github/workflows/release.yml) runs the tests, builds and checks the disk image, and publishes release `v1.1.0` with `Animation-Switch.dmg` and its checksum. Merges that don't change `VERSION` publish nothing. If the workflow fails, fix the cause in a new pull request, or press **Run workflow** on `main` after a transient failure. Re-running it for a version that is already released does nothing. See [docs/releasing.md](docs/releasing.md).
