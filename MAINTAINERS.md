## How to release a new version

Notes: we use [SemVer format](https://semver.org/).

MAJOR: breaking change.
MINOR: new feature.
PATCH: bugfix only.

## Steps

In a PR:

- bump [`HCaptcha.podspec`](./HCaptcha.podspec) version
- update [`Example/Podfile.lock`](./Example/Podfile.lock) version with `pod install` command
- update [`CHANGELOG.md`](./CHANGELOG.md) with changes since last version

After merging and tests pass:

- tag `master` with exact version from `HCaptcha.podspec` (i.e "1.7.0"). This will kick off an automated release to:
	+ Cocoapods
	+ Github Releases
	
## Implementation details

### Why do `HCaptcha-Carthage.xcodeproj` here

`Carthage` don't support concept of `subspec`, so `HCaptcha-Carthage.xcodeproj` used to achieve the similar goal

### Where logic for releasing packages for `Carthage` or `Swift package manager`

Opposite to `Cocoapods`, `Carthage` of `SPM` don't require any uploads to be used.
