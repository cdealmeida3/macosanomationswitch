# Animation Switch

A macOS menu bar utility that turns the system's UI animations off and restores them, for one person's own Macs.

## Language

**Animation**:
A built-in macOS visual transition (window open/close, Dock minimize, Mission Control, Quick Look, and so on) that the app can disable and restore.
_Avoid_: Effect, transition, motion

**Master Switch**:
The single control that disables or restores all animations the app manages at once.
_Avoid_: Main toggle, kill switch, global switch

**Animation Toggle**:
The per-animation checkbox under the master switch that decides whether the master switch manages that animation.
_Avoid_: Tweak, setting, option

**Managed Animation**:
An animation whose animation toggle is checked, so the master switch disables and restores it. Unchecked animations are left alone.
_Avoid_: Selected animation, enabled animation

**Restore**:
Return an animation to its original value.
_Avoid_: Reset, undo, re-enable

**Original Value**:
What an animation's setting was, or the fact that it was never set, at the moment the app first changed it. It may be the person's own customisation rather than Apple's default.
_Avoid_: Default, factory value, backup

**Drift**:
When something other than the app, such as a macOS update, changes a managed animation back while the master switch says it is disabled.
_Avoid_: Reset, regression

**Preset**:
A named combination of animation states the person can switch to in one step. Not in the first version.
_Avoid_: Profile, mode, scheme
