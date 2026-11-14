# Releasing

Releases are ad-hoc-signed, universal `.dmg` files on [GitHub Releases](https://github.com/cdealmeida3/macosanomationswitch/releases). The design is in [release-plan.md](release-plan.md) and [ADR 0003](adr/0003-ad-hoc-signed-dmg-on-github-releases.md).

## Publishing a new version

1. Open a pull request that changes `VERSION`, for example from `1.0.0` to `1.1.0`. `VERSION` is the only place the version is written.
2. CI builds and checks the disk image on the pull request, like on every other pull request.
3. When it merges, [`release.yml`](../.github/workflows/release.yml) runs on `main`. It runs the tests, builds the app with the run number as the build number, makes the disk image, checks it with `scripts/verify-dmg.sh`, and publishes release `v1.1.0` with `Animation-Switch.dmg` and `Animation-Switch.dmg.sha256`. It creates the tag itself, on the commit it built. Nobody pushes tags by hand.

Merges that don't change `VERSION` publish nothing.

## When the release workflow fails

- Fix the cause in a new pull request. If the fix doesn't change `VERSION`, press **Run workflow** on `main` afterwards.
- For a transient failure, such as a runner problem, press **Run workflow** on `main` (Actions → Release → Run workflow).
- Running it for a version that's already released does nothing and succeeds, so re-runs are harmless. It refuses to run from any branch but `main`.

Never bump `VERSION` from inside a workflow. A push made with the workflow's own token doesn't trigger other workflows, so the release would never run.

## After publishing

Check the [latest release](https://github.com/cdealmeida3/macosanomationswitch/releases/latest) lists both files, and that the README's link, `releases/latest/download/Animation-Switch.dmg`, downloads the new version. Then run the Install rows of the [manual checklist](manual-verification.md) on a real Mac.
