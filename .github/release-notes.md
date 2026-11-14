## Install Animation Switch {{VERSION}}

Animation Switch needs macOS 26 Tahoe or later, on Apple Silicon or Intel.

1. Download **Animation-Switch.dmg** below and open it.
2. Drag **Animation Switch** onto the **Applications** shortcut. Do this before the first launch, not from the disk image or Downloads.
3. Open Animation Switch from Applications. The icon appears in the menu bar, and Launch at login turns on.

### First launch

The app is free and open source, and it is not notarized by Apple, so macOS blocks the first launch of each new version once:

1. Open Animation Switch from Applications. macOS says it could not verify the app is free of malware. Click **Done**, not Move to Trash.
2. Open **System Settings → Privacy & Security**, scroll down to Security, and click **Open Anyway** next to the line about Animation Switch. Enter your password.
3. Click **Open** in the dialog that follows. From then on the app opens normally.

If you are comfortable with Terminal, you can instead run `xattr -dr com.apple.quarantine "/Applications/Animation Switch.app"` and then open the app.

### Updating

Quit Animation Switch, download the new disk image, drag the app to Applications and choose Replace. Each new version needs Open Anyway once, and macOS may ask you to allow the login item again.

To check the download, put `Animation-Switch.dmg.sha256` next to it and run `shasum -a 256 -c Animation-Switch.dmg.sha256`.

See the [README](https://github.com/cdealmeida3/macosanomationswitch#readme) for more.

