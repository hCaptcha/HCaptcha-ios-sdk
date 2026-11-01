# Prerequisites software

- Xcode
- Carthage
- Ruby
- Node and Yarn
- [SwiftLint 0.43.1](https://github.com/realm/SwiftLint/releases/tag/0.43.1) on `PATH` for `fastlane swift_lint`

# How to release a new version

**Note:** we use [SemVer format](https://semver.org/).

MAJOR: breaking change.
MINOR: new feature(s), backwards compatible.
PATCH: bugfix only.

## Release steps

In a PR:

- add the target SemVer version as the first heading in [`CHANGELOG.md`](./CHANGELOG.md)
- document changes since the last release, including breaking changes
- run `bundle exec fastlane ci`

After merging and tests pass, tag `master` with the exact changelog version (e.g. `4.1.0`) and publish its GitHub release. The release workflow validates the version and updates the release notes. SPM and Carthage consume the Git tag directly.

CocoaPods support ended with 4.1.0. Do not publish new pod versions.

## Implementation details FAQ

### Why do we need `HCaptcha-Carthage.xcodeproj` here?

`HCaptcha-Carthage.xcodeproj` defines the framework targets and shared schemes used to build Carthage XCFrameworks.

### Where is the logic for releasing packages for `Carthage` or `Swift Package Manager`?

`Carthage` and `SPM` resolve versions from Git tags. They do not require centralized package publishing.

### How is a release triggered?

We use GitOps. It is triggered by publishing a GitHub release for a version tag on the default branch (`master`). This must be done by an administrator, as we use tag protection. Don't tag the new version on feature branches, just update the metadata for release.

### How to test siteKey/apiKey outside SDK

Use https://accounts.hcaptcha.com/demo?sitekey=XXX