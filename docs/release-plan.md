# Downloadable DMG release: implementation plan

This is the plan for publishing Animation Switch as a `.dmg` that anyone can download from GitHub and install without Xcode. It was agreed with Carlos in a planning thread on 2026-11-14. A separate thread implements it. It builds on the v1 app described in [PLAN.md](./PLAN.md) and the decision in [ADR 0003](./adr/0003-ad-hoc-signed-dmg-on-github-releases.md).

## Why

Building from source needs Xcode 26 and XcodeGen, which is too much for someone who just wants the app, Carlos included. GitHub Actions already builds the app on a macOS runner for every PR. This plan turns that build into a release: a disk image on a GitHub Release page, with a stable download link in the README.

## Decisions

| # | Topic | Decision |
|---|---|---|
| R1 | Where it's published | GitHub Releases on this repo, one release per version, tagged `vX.Y.Z`. The `.dmg` and its SHA-256 checksum are the release assets. |
| R2 | Signing | Ad-hoc signed, as today. No Apple Developer account, no secrets in the repo. The first launch of each downloaded version is blocked once by Gatekeeper, and the person clicks **Open Anyway** in System Settings (see "First launch" below). Developer ID signing and notarization are not part of this plan. |
| R3 | When a release is published | When a merged PR changes `VERSION`. A push to `main` that changes `VERSION` publishes release `vX.Y.Z` with its `.dmg`. Other merges publish nothing. A manual "Run workflow" button (`workflow_dispatch`) on `main` does the same, for retrying a failed release. Nobody pushes tags by hand. |
| R4 | Which Macs | One universal build (`arm64` and `x86_64`), so it runs natively on Apple Silicon and on the Intel Macs that run macOS 26. Minimum macOS stays 26 Tahoe. Older releases are out, because the animation settings were only researched for 26 and 27. |
| R5 | Install | Open the `.dmg` and drag "Animation Switch" onto the Applications shortcut inside it. No installer package, no background artwork. |
| R6 | Version numbers | `X.Y.Z`. The first release is `1.0.0`. One file at the repo root, `VERSION`, is the only place the version is written. The build number is the GitHub Actions run number. |
| R7 | File names | The asset is always called `Animation-Switch.dmg`, so the README can link to `releases/latest/download/Animation-Switch.dmg` and that link never changes. The disk image's volume name carries the version ("Animation Switch 1.0.0"). |
| R8 | PR builds | The macOS CI job builds the `.dmg` on every PR and runs the same checks as a release, so a broken release build can't merge. The image is uploaded as a workflow artifact kept for 7 days, for anyone who wants to try a PR. |
| R9 | Updates | Manual. Quit the app, download the new `.dmg`, and replace the copy in Applications. Auto-update (for example Sparkle) stays out of scope. |
| R10 | Release notes | The install instructions from a template, then GitHub's generated list of merged PRs since the previous release. |

## What a person sees

1. They open the README or the [latest release](https://github.com/cdealmeida3/macosanomationswitch/releases/latest) and download `Animation-Switch.dmg`.
2. They open it and drag the app to Applications.
3. They open the app from Applications. macOS blocks it once, because it isn't notarized, and they allow it in System Settings, as described in "First launch" below.
4. The icon appears in the menu bar and "Launch at login" turns on, as in the v1 plan.

## First launch (Gatekeeper)

The app is ad-hoc signed, which is enough to run on Apple Silicon, but it isn't notarized by Apple. A downloaded copy is marked as quarantined, so the first launch is blocked. Since macOS 15, Control-click → Open no longer gets around this. The steps for the README and the release notes are:

1. Open "Animation Switch" from Applications. macOS says it could not verify the app is free of malware. Click **Done**, not Move to Trash.
2. Open System Settings → Privacy & Security, scroll to Security, and click **Open Anyway** next to the line about "Animation Switch". Enter your password.
3. Click **Open** in the dialog that follows. From then on the app opens normally.

For people comfortable with Terminal, the README also gives the alternative: `xattr -dr com.apple.quarantine "/Applications/Animation Switch.app"`, then open the app.

Things the README must also say:

- Move the app to Applications **before** the first launch. Opened straight from the disk image or Downloads, a quarantined app runs from a randomised read-only location (App Translocation), and Launch at login can register the wrong copy.
- Each new version is a new download, so the Open Anyway step happens once per version.
- Every build has a different ad-hoc signature, so after an update macOS may ask again to allow the login item. The app already shows an inline warning for that, which opens Login Items settings.
- If macOS ever says the app "is damaged and can't be opened", the download or copy broke the signature. The CI checks below exist to stop that shipping, so treat it as a bug.

## Versioning

- Add a `VERSION` file at the repo root containing `1.0.0` and a newline.
- `scripts/build-app.sh` reads it and passes `MARKETING_VERSION=$(cat VERSION)` to `xcodebuild`. It passes `CURRENT_PROJECT_VERSION` from the `BUILD_NUMBER` environment variable, defaulting to `1` for local builds.
- Remove the hard-coded `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` values from `App/project.yml`, or make them read the same file, so the version can't be written in two places. Opening the project in Xcode must still build.
- CI checks that `CFBundleShortVersionString` in the built `Info.plist` equals the contents of `VERSION`.

## Universal build

- Set `ARCHS = arm64 x86_64` and `ONLY_ACTIVE_ARCH = NO` for Release in `App/project.yml`, rather than relying on Xcode's defaults.
- The Swift package dependencies build for both architectures through the app target. Nothing changes for the Linux job.
- CI checks `lipo -archs "build/Animation Switch.app/Contents/MacOS/Animation Switch"` prints both `arm64` and `x86_64`.

## Making the disk image

Add `scripts/make-dmg.sh`, which takes the built app and writes `build/Animation-Switch.dmg`. Use only tools that ship with macOS:

1. Make a staging folder containing a copy of `build/Animation Switch.app` (copied with `ditto`, so the signature and extended attributes survive) and a symlink named `Applications` pointing to `/Applications`.
2. `hdiutil create -volname "Animation Switch $VERSION" -srcfolder <staging> -format UDZO -ov build/Animation-Switch.dmg`.
3. Write `build/Animation-Switch.dmg.sha256` with `shasum -a 256`, containing only the file name, not the build path, so `shasum -c` works after download.

Add `scripts/verify-dmg.sh`, used by both CI and the release workflow:

- `hdiutil verify` passes on the image.
- It mounts read-only with `hdiutil attach -nobrowse -readonly`, finds exactly `Animation Switch.app` and an `Applications` symlink to `/Applications`, and runs `codesign --verify --deep --strict` on the app inside the mounted image. That last check catches the "app is damaged" failure, which comes from a signature broken during copying.
- It checks the app's architectures and version, as above, on the mounted copy.
- It detaches the image whether the checks pass or fail.

The script exits non-zero on any failure. Never skip or soften one of these checks to get a green run.

## CI changes (`.github/workflows/ci.yml`)

In the existing macOS job, after "Build the app":

- set `BUILD_NUMBER: ${{ github.run_number }}`,
- run `scripts/make-dmg.sh` and `scripts/verify-dmg.sh`,
- upload `build/Animation-Switch.dmg` with `actions/upload-artifact` (name `Animation-Switch-dmg`, `retention-days: 7`).

The job stays the auto-merge gate. Nothing in it publishes anything.

## Release workflow (`.github/workflows/release.yml`)

Triggers:

```yaml
on:
  push:
    branches: [main]
    paths: [VERSION]
  workflow_dispatch:
```

The merges that bump `VERSION` are made through Carlos's GitHub account, so they trigger `push` events. A merge made with the workflow's own `GITHUB_TOKEN` would not trigger it, so never automate the version bump from inside a workflow. For `workflow_dispatch`, refuse to run on any ref other than `main`.

Job, on `macos-26`:

1. `permissions: contents: write`, and `concurrency: { group: release, cancel-in-progress: false }` so two releases never race.
2. Check out the repo with full history and tags (`fetch-depth: 0`), so generated notes can find the previous release.
3. Read `VERSION`. Check it matches `X.Y.Z`. If a GitHub Release for `vX.Y.Z` already exists, log "v1.2.3 is already released" and stop successfully, so re-runs are harmless.
4. Run `swift test`. A release never ships from a commit whose tests fail.
5. `brew install xcodegen`, then `BUILD_NUMBER=${{ github.run_number }} ./scripts/build-app.sh`, `scripts/make-dmg.sh` and `scripts/verify-dmg.sh`.
6. Publish with the `gh` CLI that's preinstalled on the runner, using `GH_TOKEN: ${{ github.token }}`:
   `gh release create "v$VERSION" build/Animation-Switch.dmg build/Animation-Switch.dmg.sha256 --target "$GITHUB_SHA" --title "Animation Switch $VERSION" --notes-file <rendered template> --generate-notes`.
   This creates the tag on the exact commit that was built. Check that `--notes-file` and `--generate-notes` combine as expected (the template first, then the generated list). If they don't, render the generated notes with `gh api repos/{owner}/{repo}/releases/generate-notes` and append them.
7. Keep the release notes template in `.github/release-notes.md`, with a `{{VERSION}}` placeholder. It holds the install steps from "What a person sees", the first-launch steps, and a link to the README.

No third-party actions are needed beyond `actions/checkout` and `actions/upload-artifact`, which CI already uses.

## README and docs changes

- README: a new **Download** section at the top of the install instructions, linking to `releases/latest/download/Animation-Switch.dmg` and to the latest release page, with the install and first-launch steps. Replace "so you build it from source" in the intro. Keep "Build and run from source" as the second option.
- README: a short **Updating** section (R9), and a line on checking the download with `shasum -a 256 -c Animation-Switch.dmg.sha256`.
- `docs/manual-verification.md`: step 1 of "Before you start" becomes "Install the release you're testing from its `.dmg`", with building from source as the alternative. Add a row for the install itself: the `.dmg` opens, the drag to Applications works, first launch works as the README says, and Launch at login works after the move.
- `docs/PLAN.md`: in "Out of scope for v1", point to this plan for releases. Change Q11 to say that releases are ad-hoc-signed `.dmg` files on GitHub Releases, and that Developer ID signing and notarization are still not planned.
- Add a "How to release" paragraph to the README's contributor section, or a short `docs/releasing.md`: "To publish a new version, open a PR that changes `VERSION` (for example `1.0.0` to `1.1.0`). When it merges, the release workflow builds, checks and publishes `v1.1.0`. If the workflow fails, fix the cause in a new PR, or press Run workflow on `main` after a transient failure."

## Testing

- The checks in `scripts/verify-dmg.sh` run on every PR and every release, so the image is proven to mount, contain a validly signed universal app of the right version, and offer the Applications shortcut.
- Optional smoke test, in the macOS CI job: copy the app out of the mounted image to a temporary folder, launch its executable in the background, wait 5 seconds, check the process is still alive, and terminate it. Add it only if it passes reliably on the runner. A fresh runner has the Master Switch on, so launching writes no system settings. If it can't be made reliable, leave it out rather than marking it as allowed to fail.
- Gatekeeper's first-launch behaviour can't be tested in CI, because the runner's downloads aren't quarantined. Carlos checks it once on his Mac with the first real release, using the new install row in the manual checklist.

## Suggested order of work

Each step is one PR that merges on its own when every check is green, per Carlos's rule.

1. `VERSION` file, version and build number wiring in `build-app.sh` and `project.yml`, explicit universal architectures, and the CI checks for version and architectures.
2. `scripts/make-dmg.sh` and `scripts/verify-dmg.sh`, run in the macOS CI job, with the artifact upload. Add the smoke test here if it's reliable.
3. `.github/workflows/release.yml` and `.github/release-notes.md`. Don't change `VERSION` in this PR. With `VERSION` still unreleased, merging this PR runs nothing, because the `paths` filter only fires when `VERSION` changes. Check the workflow by reading it carefully and, if possible, validate its syntax with `actionlint`.
4. README, manual checklist and release docs, as listed above.
5. Publish `1.0.0`: `VERSION` is already `1.0.0` from step 1, so press Run workflow on `main` (the GitHub MCP `actions_run_trigger` tool can do this), and watch the run until it finishes. Don't bump the version only to trigger it. Then check the release page lists `Animation-Switch.dmg` and its `.sha256`, and that `releases/latest/download/Animation-Switch.dmg` downloads (for example with `curl -sIL`). Tell Carlos the link, and ask him to run the install row of the manual checklist on his Mac.

## Out of scope

Auto-update, a Homebrew cask, a Mac App Store build, a custom disk image background or window layout, an installer `.pkg`, release builds for macOS 25 or earlier, and publishing from PRs.
