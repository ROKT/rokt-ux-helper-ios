# Releasing

Releases are prepared by the [Release – Draft](https://github.com/ROKT/rokt-ux-helper-ios/actions/workflows/release-draft.yml)
workflow and published by the [Release – Publish](https://github.com/ROKT/rokt-ux-helper-ios/actions/workflows/release-publish.yml)
workflow.

The draft workflow updates `VERSION`, `RoktUXHelper.podspec`, and
`CHANGELOG.md`, then opens a release PR. After that PR is reviewed, tested, and
merged, the publish workflow creates the GitHub release and tag used by Swift
Package Manager, then publishes the podspec to CocoaPods.

## Standard releases from main

Use this flow for normal patch, minor, or major releases on the main release
line:

1. Open the "Actions" tab in GitHub.
2. Select the "Release – Draft" workflow.
3. Set "Use workflow from" to `main`.
4. Choose the required version bump: `patch`, `minor`, or `major`.
5. Run the workflow and review the generated `release/<version>` PR.
6. Merge the release PR after checks pass.

When the release PR is merged to `main`, "Release – Publish" creates the GitHub
release, tags the commit, and publishes `RoktUXHelper.podspec` to CocoaPods.
Stable releases from `main` are marked as GitHub "Latest".

## Maintenance patch releases

Use maintenance branches for patch releases after a stable major or minor
release has landed on `main`.

Create the maintenance branch from the stable release tag or release commit:

```bash
git fetch origin --tags
git checkout -b maintenance/1.0.x 1.0.0
git push --set-upstream origin maintenance/1.0.x
```

To release a patch from that maintenance line:

1. Cherry-pick or merge the required patch changes into `maintenance/X.Y.x`.
2. Open the "Release – Draft" workflow.
3. Set "Use workflow from" to the maintenance branch, for example
   `maintenance/1.0.x`.
4. Choose `patch` as the version bump.
5. Run the workflow and review the generated `release/<version>` PR.
6. Merge the release PR back into the maintenance branch.

When the release PR is merged to `maintenance/*`, "Release – Publish" creates
the GitHub release, tags the commit, and publishes the patch podspec to
CocoaPods. Maintenance releases are not marked as GitHub "Latest"; only stable
releases from `main` update the latest release badge.

## Workflow behavior

`Release – Draft` can run from `main` or `maintenance/*` branches. Maintenance
branch drafts must use a patch bump.

`Release – Publish` runs only when `VERSION` changes on `main` or
`maintenance/*`, and it ignores branch create/delete push events.

Snapshot builds are not part of this repository's release flow. Publishing is
tied to versioned releases.

## CHANGELOG.md

`CHANGELOG.md` is generated automatically by the `Release – Draft` workflow from
the git history and conventional commit PR titles. Do not edit `CHANGELOG.md` in
feature branches; manual entries will be overwritten when the release PR is
drafted. Write clear, conventional commit-style PR titles, for example
`feat(richtext): support <p> tag`, and the changelog entry will be produced at
release time.
