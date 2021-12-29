# Prerequisites software

- Xcode
- Carthage
- Cocoapods
- Ruby
- Node

# How to release a new version

**Note:** we use [SemVer format](https://semver.org/).

MAJOR: breaking change.
MINOR: new feature(s), backwards compatible.
PATCH: bugfix only.

## Release steps

In a PR:

- bump [`HCaptcha.podspec`](./HCaptcha.podspec) version
- update [`Example/Podfile.lock`](./Example/Podfile.lock) version with `pod install` command
- update [`CHANGELOG.md`](./CHANGELOG.md) with changes since last version

After merging and tests pass:

- tag `master` with exact version from `HCaptcha.podspec` (i.e "1.7.0"). This will kick off an automated release to:
	+ Cocoapods
	+ Github Releases
	
.. and that's it!

## Implementation details FAQ

### Why do we need `HCaptcha-Carthage.xcodeproj` here?

`Carthage` doesn't support the concept of `subspec`, so `HCaptcha-Carthage.xcodeproj` is used to achieve a similar goal.

### Where is the logic for releasing packages for `Carthage` or `Swift Package Manager`?

Unlike `Cocoapods`, `Carthage` and `SPM` are decentralized. They do not require any centralized updates per version.
