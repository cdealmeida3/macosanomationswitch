# Animation Switch v1: implementation plan

This is the plan for the first version of Animation Switch. It was agreed with Carlos in a planning interview on 2026-11-14. A separate thread implements it. Use the words in [GLOSSARY.md](../GLOSSARY.md) for names in code, UI and docs. The architecture decisions are in [docs/adr/](./adr/). The evidence for each macOS setting is in [docs/research/animation-settings.md](./research/animation-settings.md).

## What it is

Animation Switch is a menu bar app that disables macOS system animations and restores them. It has one **Master Switch**, with an **Animation Toggle** per animation underneath. It is for Carlos's own Macs first, open source on GitHub, and never in the Mac App Store ([ADR 0001](./adr/0001-distribute-outside-the-app-store.md)).

## Decisions

These are the interview answers, numbered as they were asked.

| # | Topic | Decision |
|---|---|---|
| Q1 | Purpose | Disable macOS system UI animations and restore them. It does not speed them up and does not touch animations inside one app. |
| Q2 | Controls | One Master Switch, with per-animation toggles underneath. Presets are not in v1. |
| Q3 | Form factor | Menu bar app with no Dock icon (`LSUIElement`). |
| Q4 | Distribution | Own use first, open source on GitHub, outside the App Store. |
| Q5 | macOS versions | The current release and the one before it: macOS 27 Golden Gate and macOS 26 Tahoe. |
| Q6 | Restore | Puts back the **Original Value**, which is what the setting was the first time the app changed it, or the fact that it was absent. It never writes Apple's "default". If the setting was absent, Restore deletes the key. |
| Q7 | Master Switch vs toggles | The toggles choose the **Managed Animations**. Flipping the Master Switch to off disables only the checked ones. Restore brings back only what the app disabled. Unchecked animations are never touched. |
| Q8 | Restarts | The app restarts Dock and Finder itself, only the processes the change touched, and only once per flip, not once per animation. |
| Q9 | Launch and drift | "Launch at login" is a menu item, on by default. On launch, if the Master Switch says animations are off, the app re-applies any managed animation that has **Drifted**. |
| Q10 | Stack and merge gate | Swift and a SwiftUI `MenuBarExtra`. All logic lives in a Swift package with no UI, and a GitHub Actions macOS job is the auto-merge gate ([ADR 0002](./adr/0002-ui-free-core-package-gated-by-macos-ci.md)). |
| Q11 | Signing | Ad-hoc signing. Releases are ad-hoc-signed `.dmg` files on GitHub Releases ([release plan](./release-plan.md), [ADR 0003](./adr/0003-ad-hoc-signed-dmg-on-github-releases.md)). Developer ID signing and notarization are still not planned. |
| Q12 | Name | The app is "Animation Switch". The repo keeps its current name. |
| Q13 | Menu layout | Master Switch at the top, then the toggles grouped by area, then "Launch at login", "Restore all and quit" and "Quit". The menu bar icon shows the state. |
| Q14 | Toggle changes while off | While animations are off, checking a toggle disables that animation immediately, and unchecking it restores it immediately. |
| Q15 | Quitting | "Quit" leaves the settings as they are. "Restore all and quit" restores every animation the app disabled, then quits. |
| Q16 | Failures and caveats | Shown as an inline warning on the toggle, with a one-line explanation. Never a pop-up alert. |
| Q17 | Global shortcut | Not in v1. |
| Q18 | Method | Test-first (use the repo's `tdd` skill). Logic is tested against fakes, and one macOS CI test writes to a throwaway preferences domain. |
| Q19 | Reduce Motion | Not controlled by the app. The menu shows whether it is on and has a button that opens the Motion settings pane. |
| Q20 | v1 catalog | The 13 animations in the catalog below. Mail and Launchpad are out. |
| Q21 | Initial toggles | Every toggle starts checked except smooth scrolling. |
| Q22 | Proving the settings work | A manual checklist is run once on a real Mac per release, and any animation that does nothing there is dropped. A release Carlos doesn't own is best-effort. Carlos hasn't said yet which release his Mac runs. |
| Q23 | Already-running apps | Settings that apply only to newly opened apps show the note "Applies to apps you open from now on". The app never relaunches other apps. |

## Catalog (v1)

Apple ships every one of these keys absent. "Restart" is what the app restarts after a change. For "None (note)", the app shows the Q23 note instead.

| Group | Animation (menu label) | Domain | Key | Type | Disabled value | Restart | Starts checked |
|---|---|---|---|---|---|---|---|
| Windows | Window open and close | NSGlobalDomain | `NSAutomaticWindowAnimationsEnabled` | bool | `false` | None (note) | yes |
| Windows | Sheets and window resizing | NSGlobalDomain | `NSWindowResizeTime` | float | `0.001` (`0` is reportedly ignored) | None (note) | yes |
| Windows | Full-screen toolbar slide | NSGlobalDomain | `NSToolbarFullScreenAnimationDuration` | float | `0` | None (note) | yes |
| Windows | Versions browser | NSGlobalDomain | `NSDocumentRevisionsWindowTransformAnimation` | bool | `false` | None (note) | yes |
| Scrolling | Smooth scrolling | NSGlobalDomain | `NSScrollAnimationEnabled` | bool | `false` | None (note) | **no** |
| Finder | Column view scrolling | NSGlobalDomain | `NSBrowserColumnAnimationSpeedMultiplier` | float | `0` | Finder (plus the note) | yes |
| Finder | Quick Look zoom | NSGlobalDomain | `QLPanelAnimationDuration` | float | `0` | Finder (plus the note) | yes |
| Finder | Finder animations | com.apple.finder | `DisableAllAnimations` | bool | `true` | Finder | yes |
| Dock | Auto-hide delay | com.apple.dock | `autohide-delay` | float | `0` | Dock | yes |
| Dock | Auto-hide slide | com.apple.dock | `autohide-time-modifier` | float | `0` | Dock | yes |
| Dock | Bounce when opening apps | com.apple.dock | `launchanim` | bool | `false` | Dock | yes |
| Dock | Minimize effect (Scale instead of Genie) | com.apple.dock | `mineffect` | string | `scale` | Dock | yes |
| Mission Control | Mission Control transition | com.apple.dock | `expose-animation-duration` | float | `0` | Dock | yes |

Notes on single rows:

- **Auto-hide delay and slide** only matter when the Dock auto-hides. The app must never turn auto-hide on. When `com.apple.dock autohide` is false, show the inline note "Only applies when the Dock hides automatically".
- **Minimize effect** has no "none" value, and `scale` is the fastest one. If the person already uses `scale` or `suck`, that is the Original Value, and Restore puts it back unchanged.
- **Mission Control transition** reportedly affects only keyboard and hot-corner entry, not trackpad gestures. The toggle's inline note says so.
- Most rows have only "listed" evidence for 26 and 27, not tested evidence. The manual checklist below decides which rows survive.

## Reduce Motion (read only)

- Read it with `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`, and refresh it on `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`.
- Show a menu row like "Reduce Motion: On/Off" with a button that opens System Settings → Accessibility → Motion. Find the right `x-apple.systempreferences:` URL for 26 and 27, falling back to the Accessibility pane.
- Never write `com.apple.universalaccess`. Writes fail without Full Disk Access, and an unsigned app would lose that grant on every rebuild.

## Behaviour

**State the app keeps** lives in the app's own preferences domain:
- whether the Master Switch is off (animations disabled),
- the set of Managed Animations, seeded from the "Starts checked" column on first launch,
- the Original Value of each animation the app has currently disabled (a value, or "absent").

**Flipping the Master Switch off:** for each managed animation, if no Original Value is saved, save the current value (or "absent"). Then write the disabled value. Collect the processes to restart and restart each once at the end.

**Flipping it on (Restore):** for each animation with a saved Original Value, write it back, or delete the key if it was absent. Then clear the saved value, so the next flip off captures any new customisation. Restart the affected processes once.

**Checking or unchecking a toggle:** while the Master Switch is on, this only changes the managed set. While it is off, checking disables that one animation now, and unchecking restores it now (Q14).

**On launch:** if the Master Switch is off, compare each managed animation's current value with its disabled value. Re-apply any that drifted, without touching their saved Original Value, then restart once. This also undoes a change the person made in System Settings while the switch was off. That is accepted for v1.

**Restore all and quit:** restore every animation that has a saved Original Value, regardless of the managed set, then quit.

**Failures:** if a write or read-back fails, keep the toggle's state honest, show the inline warning (Q16), and carry on with the other animations. One failure never blocks the rest.

**Writing other domains:** use CFPreferences (`CFPreferencesSetValue` / `CFPreferencesSetAppValue` plus synchronize), never direct plist edits, because cfprefsd caches values. NSGlobalDomain is `kCFPreferencesAnyApplication`, current user, any host. Restart processes with `killall Dock` and `killall Finder`, or the equivalent `NSRunningApplication` terminate. Finder relaunches itself.

## Architecture

The design follows [ADR 0002](./adr/0002-ui-free-core-package-gated-by-macos-ci.md).

- **Core Swift package** (for example `AnimationSwitchCore`), with no AppKit or SwiftUI imports, building and testing on both Linux and macOS:
  - the catalog of Animation definitions (id, group, label, domain, key, value type, disabled value, restart target, starts checked, optional inline note),
  - a preferences-store interface (read a key's value or absence, write, delete) with an in-memory fake for tests,
  - a process-restarter interface with a recording fake,
  - an app-state store interface with a fake,
  - one engine that owns the behaviour above and returns, for every operation, a per-animation outcome (applied, restored, unchanged, failed with a reason, note to show). The UI renders those outcomes and decides nothing itself.
- **macOS-only adapters**, behind `#if os(macOS)` or in a separate macOS-only target: a CFPreferences store, a Dock/Finder restarter, and a UserDefaults-backed app-state store.
- **The app target**: SwiftUI `MenuBarExtra`, `LSUIElement = YES`, "Launch at login" through `SMAppService.mainApp`. Check that this works for an ad-hoc-signed build, and if it doesn't, give the toggle an inline warning rather than hiding it. Prefer a generated project (for example XcodeGen's `project.yml`) over a committed `.xcodeproj`, so the project can be edited from the Linux container and diffs stay readable. The implementer may choose otherwise if there's a good reason.
- Minimum deployment target: macOS 26.

## Testing and CI

- Work test-first with the `tdd` skill. Most tests drive the engine through the fakes: Original Values are saved once and restored exactly, absent keys get deleted, unchecked animations are untouched, each process restarts once per flip, drift is re-applied on launch, toggles take effect while the switch is off, one failure doesn't stop the rest, and "Restore all" ignores the managed set.
- One macOS-only integration test uses the real CFPreferences store against a throwaway domain (for example `dev.animationswitch.tests.<uuid>`). It writes, reads back, deletes and cleans up. It must never touch the real Dock, Finder or global domains.
- The cloud container has no Swift toolchain right now. Install one if the container's network allows it, and otherwise rely on CI.
- GitHub Actions on every PR:
  - **Linux**: `swift test` for the core package.
  - **macOS**: on the newest available runner, `swift test`, then generate the project and build the app with code signing disabled or ad-hoc signing.
- Per Carlos's rule, push, open a PR, and merge once every check is green. Never merge with a failing or skipped check.

## Manual verification checklist

Add this as `docs/manual-verification.md` in the implementation, with a results column per release. Carlos runs it once per release on a real Mac. For each catalog row: flip the Master Switch off, check that the animation is visibly gone (relaunching the test app where the note says so), flip it on, and check that the animation is back. Also check: Restore brings back a customised value (set the Dock minimize effect to Scale yourself first), "Restore all and quit" leaves no keys behind (`defaults read` the touched keys), Reduce Motion status updates live, and Launch at login works. Any row that does nothing on a release is dropped from the catalog for that release, and the research doc is updated.

## Out of scope for v1

Presets, a global keyboard shortcut, a CLI, changing Reduce Motion or Reduce Transparency, Mail animations, Launchpad (removed in macOS 26), Spaces switching speed (no setting exists), Developer ID signed or notarized releases, auto-update, and macOS 15 or earlier. Downloadable releases are covered by the [release plan](./release-plan.md).

## Suggested order of work

Each step should be one PR that can merge on its own.

1. Package skeleton and CI: core package, one trivial test, Linux and macOS jobs green.
2. Catalog, preferences-store interface and fake, CFPreferences store, and the throwaway-domain integration test.
3. Engine: flipping off and on with Original Values, the managed set, restart batching, and outcomes.
4. Toggles while off, drift on launch, and "Restore all".
5. Menu bar app: menu layout, state icon, toggles with inline notes and warnings, Reduce Motion row, "Launch at login", "Quit", and "Restore all and quit".
6. README with build-from-source and run instructions, plus `docs/manual-verification.md`.
