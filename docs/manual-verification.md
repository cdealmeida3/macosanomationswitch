# Manual verification checklist

Automated tests prove the app writes and restores the right settings. They can't prove a setting actually removes its animation, so run this once per macOS release on a real Mac (plan Q22). A release nobody owns is best-effort.

Record each result as ✅ (works), ❌ (does nothing) or a short note. Any row marked ❌ on a release is dropped from the catalog for that release, and [docs/research/animation-settings.md](research/animation-settings.md) is updated with what you saw.

## Before you start

1. Build and open the app (see the [README](../README.md#build-and-run-from-source)).
2. Write down which release and build you're on: `sw_vers`.
3. Save your current values so you can compare later:
   ```sh
   for k in NSAutomaticWindowAnimationsEnabled NSWindowResizeTime NSToolbarFullScreenAnimationDuration \
            NSDocumentRevisionsWindowTransformAnimation NSScrollAnimationEnabled \
            NSBrowserColumnAnimationSpeedMultiplier QLPanelAnimationDuration; do
     printf '%s: ' "$k"; defaults read -g "$k" 2>/dev/null || echo absent
   done
   for k in autohide autohide-delay autohide-time-modifier launchanim mineffect expose-animation-duration; do
     printf '%s: ' "$k"; defaults read com.apple.dock "$k" 2>/dev/null || echo absent
   done
   printf 'DisableAllAnimations: '; defaults read com.apple.finder DisableAllAnimations 2>/dev/null || echo absent
   ```
4. Check every toggle, including Smooth scrolling.

## Each animation

For each row: flip the Master Switch **off** and check the animation is gone. Then flip it **on** and check the animation is back. Where the row says "new app", quit and reopen the test app after each flip, because the setting only reaches apps opened afterwards.

| # | Animation | How to see it | macOS 26 Tahoe | macOS 27 Golden Gate |
|---|---|---|---|---|
| 1 | Window open and close | New app: open and close a TextEdit window | | |
| 2 | Sheets and window resizing | New app: TextEdit → File → Save… (the sheet slides in) | | |
| 3 | Full-screen toolbar slide | New app: Safari in full screen, move the pointer to the top edge | | |
| 4 | Versions browser | New app: TextEdit → File → Revert To → Browse All Versions… | | |
| 5 | Smooth scrolling | New app: Safari, press Page Down on a long page | | |
| 6 | Column view scrolling | Finder in column view, walk down several folder levels | | |
| 7 | Quick Look zoom | Select a file in Finder and press Space | | |
| 8 | Finder animations | Finder → Get Info on a file (the window zooms open) | | |
| 9 | Auto-hide delay | Turn on Dock auto-hide first. Move the pointer to the Dock edge | | |
| 10 | Auto-hide slide | Same as 9, and watch the Dock slide in | | |
| 11 | Bounce when opening apps | Open an app from the Dock | | |
| 12 | Minimize effect | Minimize a window. Off is Scale, on is your usual effect | | |
| 13 | Mission Control transition | Open Mission Control with the keyboard (F3 or Control-Up) or a hot corner. Trackpad gestures are expected to keep animating | | |

## Behaviour

| # | Check | macOS 26 Tahoe | macOS 27 Golden Gate |
|---|---|---|---|
| 14 | **Customised value comes back.** With the switch on, set System Settings → Desktop & Dock → Minimize windows using → Scale effect. Flip off, flip on. It's still Scale, and `defaults read com.apple.dock mineffect` says `scale`. Then try it with the hidden value: `defaults write com.apple.dock mineffect suck; killall Dock`, flip off and on, and check it reads `suck` again. | | |
| 15 | **Restore all and quit leaves no keys behind.** Starting from the values you saved above, flip off, then choose Restore all and quit. Run the commands from "Before you start" again. Every value matches what you saved, and keys that were absent are absent. | | |
| 16 | **Unchecked toggles are left alone.** Uncheck Bounce when opening apps, set `defaults write com.apple.dock launchanim -bool true; killall Dock`, flip off. The Dock still bounces. | | |
| 17 | **Toggles while off.** With the switch off, uncheck Bounce: it comes back at once. Check it again: it's gone at once. | | |
| 18 | **Drift on launch.** Flip off and quit (plain Quit). Run `defaults delete com.apple.dock launchanim; killall Dock`, then open the app. The Dock stops bouncing again. | | |
| 19 | **Dock and Finder restart once.** Flip off. The Dock and Finder each blink once, not once per animation. | | |
| 20 | **Auto-hide note.** With Dock auto-hide off, the two auto-hide rows say "Only applies when the Dock hides automatically". Turn auto-hide on and reopen the menu: the note is gone. | | |
| 21 | **Reduce Motion row updates live.** Keep the menu open, or reopen it, while you switch Reduce Motion in System Settings. The row follows. "Open Settings" lands on the pane that has Reduce Motion (Accessibility → Display on 26, Accessibility → Motion on 27). | | |
| 22 | **Launch at login.** It's on after the first launch. Log out and back in: the app is running. Turn it off, log out and in: it isn't. Note any warning the menu shows for this ad-hoc-signed build. | | |
| 23 | **Quit keeps settings.** Flip off, then plain Quit. Animations stay off. | | |
| 24 | **No Dock icon.** The app shows only in the menu bar, never in the Dock or the app switcher. | | |

## Results log

| Date | macOS build | Who | Rows dropped | Notes |
|---|---|---|---|---|
| | | | | |
