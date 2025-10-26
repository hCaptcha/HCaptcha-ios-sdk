# HCaptcha

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-orange.svg)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/HCaptcha)](http://cocoapods.org/pods/HCaptcha)
[![Platform](https://img.shields.io/badge/Platform-iOS-blue)](http://cocoapods.org/pods/HCaptcha)
[![iOS](https://img.shields.io/badge/iOS-12.0%20--%2018.0-blue.svg)](https://developer.apple.com/support/app-store/)
[![Xcode](https://img.shields.io/badge/Xcode-14.3.1%20--%2016.1-blue.svg)](https://developer.apple.com/xcode/)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Build](https://github.com/hCaptcha/HCaptcha-ios-sdk/actions/workflows/workflow.yml/badge.svg)](https://github.com/hCaptcha/HCaptcha-ios-sdk/actions/workflows/workflow.yml)

-----

- [Installation](#installation)
   * [Cocoapods](#cocoapods)
   * [Carthage](#carthage)
   * [SPM](#spm)
- [Requirements](#requirements)
- [Pre-requisites](#pre-requisites)
- [Examples](#examples)
- [Use cases](#use-cases)
   * [Setting the host override (optional)](#setting-the-host-override-optional)
   * [Change widget theme](#change-widget-theme)
   * [Alternate endpoint (optional)](#alternate-endpoint-optional)
   * [More params for Enterprise (optional)](#more-params-for-enterprise-optional)
   * [Enabling the visible checkbox flow](#enabling-the-visible-checkbox-flow)
   * [Using landscape instead of portrait orientation](#using-landscape-instead-of-portrait-orientation)
   * [SDK Events](#sdk-events)
   * [Token expiration](#token-expiration)
   * [Disable new token fetch on expiry](#disable-new-token-fetch-on-expiry)
   * [MFA Phone Support](#mfa-phone-support)
   * [Testing Examples with SPM](#testing-examples-with-spm)
- [Compiled size](#compiled-size-impact-on-including-in-your-app)
- [Known issues](#known-issues)
- [License](#license)
- [Troubleshooting](#troubleshooting)

Add [hCaptcha](https://www.hcaptcha.com/) to your project. This library automatically handles hCaptcha's events and returns a validation token, presenting the challenge via a modal if needed.

#### _Warning_ ⚠️

To secure your application, you need to send the token received here to your backend for server-side validation via the `api.hcaptcha.com/siteverify` endpoint.

## Installation

HCaptcha is available through [CocoaPods](http://cocoapods.org) and packaged for [Carthage](https://github.com/Carthage/Carthage) and [SPM](https://www.swift.org/package-manager/) (Swift Package Manager).

To install it, simply add the following line to your dependencies file:

### Cocoapods
``` ruby
pod "HCaptcha"
# or
pod "HCaptcha/RxSwift"
```

### Carthage
``` ruby
github "hCaptcha/HCaptcha-ios-sdk"
```

Carthage will create two different frameworks named `HCaptcha` and `HCaptcha_RxSwift`, the latter containing the RxSwift extension for the HCaptcha framework.

Known issues:
 - Carthage doesn't support prebuilt zips for `xcframework` so use `--no-use-binaries` - https://github.com/Carthage/Carthage/issues/3130
 - Carthage has a `RxSwift` build issue, also avoidable via `--no-use-binaries` - https://github.com/Carthage/Carthage/issues/3243


### SPM
Standard SPM formula: uses [Package.swift](./Package.swift)

## Requirements

| Platform | Requirements               |
|----------|----------------------------|
| iOS      | :white_check_mark: >= 12.0 |
| WatchOS  | :heavy_multiplication_x:   |

## Pre-requisites

Once you have the hCaptcha `apiKey` (also referred to as `sitekey`, which can be obtained at [`https://dashboard.hcaptcha.com/sites`](https://dashboard.hcaptcha.com/sites)),

the hCaptcha `apiKey` can be specified in `Info.plist` keys or can be passed as parameters when instantiating `HCaptcha()`.

For the Info.plist configuration, add `HCaptchaKey` (sitekey) and `HCaptchaDomain` (with a protocol, i.e. https://) to your Info.plist.

- `HCaptchaKey` is your hCaptcha sitekey.
- `HCaptchaDomain` should be a string like `https://www.your.com`

If you prefer to keep the information out of the Info.plist, you can instead use:

``` swift
let hcaptcha = try? HCaptcha(
    apiKey: "YOUR_HCAPTCHA_KEY", 
    baseURL: URL(string: "YOUR_HCAPTCHA_DOMAIN")!
)

...
```

**Notes**:

- in most cases `baseURL` can be `http://localhost`. This value is mainly used for your convenience in analytics.
- `baseURL` should match `HCaptchaDomain` if specified; it controls the URI used to initialize the hCaptcha session. Example: `https://www.your.com`

## Examples

If you are looking for a complete example please check links below:

- [UIKit Example](./Example/UIKit-Example/README.md)
- [SwiftUI Example](./Example/SwiftUI-Example/README.md)
- [RxSwift Example](./Example/RxSwift-Example/README.md)
- [SwiftUI Passive Example](./Example/Passive-Example/README.md)
- [Objective-C Example](./Example/ObjC-Example/README.md)

## Use cases

### Change the locale

By default, `Locale.current` is used to automatically set the language for the SDK, but this behavior can be changed by explicitly passing the `locale` parameter to `HCaptcha`:

``` swift
let hcaptcha = try? HCaptcha(
    ...
    locale: Locale(identifier: "zh-CN"),
    ...
)

...
```

### Setting the host override (optional)

Since this SDK uses local resources, you may want to set a host override for better tracking and enforcement of siteverify parameters.

You can achieve this by passing the extra param `host`:

``` swift
let hcaptcha = try? HCaptcha(
    ...
    host: "your-domain.com",
    ...
)

...
```

Note: this should be the **bare** host, i.e. not including a protocol prefix like https://.

### Change widget theme

The SDK supports three built-in themes: `light`, `dark`, and `contrast`

``` swift
let hcaptcha = try? HCaptcha(
    ...
    theme: "dark", // "light" or "contrast"
    ...
)

...
```

For Enterprise sitekeys we also support custom themes via the [`customTheme` parameter](https://docs.hcaptcha.com/enterprise/feature_theme/), described below.

### Alternate endpoint (optional)

If you are an Enterprise user with first-party hosting access, you can use your own endpoint (i.e. verify.your.com).

You can then enable it in your code:

``` swift
let hcaptcha = try? HCaptcha(
    ...
    endpoint: URL("https://custom.endpoint")!,
    ...
)

...
```

### More params for Enterprise (optional)

Enterprise params like:

 - `reportapi` (string)
 - `assethost` (string)
 - `imghost` (string)
 - `sentry` (bool)
 - `customTheme` (string representation of JS Object or JSON; see [Enterprise docs](https://docs.hcaptcha.com/enterprise/feature_theme))

Can be passed via `HCaptcha(...)`

Please see the [hCaptcha Enterprise documentation](https://docs.hcaptcha.com/enterprise/) for more details.

**Note**: The `rqdata` parameter has been moved from `HCaptchaConfig` to `HCaptchaVerifyParams` for better API consistency. The old `rqdata` property in `HCaptchaConfig` is now deprecated, and will be removed in the next major version.

### Enabling the visible checkbox flow

This iOS SDK assumes by default that you want an "invisible" checkbox, i.e. that triggering the hCaptcha flow from within your app should either return a token or show the user a challenge directly. (Note: "invisible" refers to the *checkbox*. If you want no or few visual challenges, choose Passive or 99.9% Passive as the behavior type for the sitekey in the hCaptcha dashboard.)

If you instead want the classic "normal" or "compact" checkbox behavior of showing a checkbox to tick and then either closing or showing a challenge, you can pass `size` to the HCaptcha initializer.

```swift
let hcaptcha = try? HCaptcha(size: .compact)
```

And you will now get the desired behavior.

### Using landscape instead of portrait orientation

The `orientation` argument can be set either `.portrait` or `.landscape`  orientation to adjust challenge modal behavior.

```swift
let hcaptcha = try? HCaptcha(orientation: .landscape)
```

By default, orientation is portrait and does not reflow.

However, if you have an app used exclusively in landscape mode (e.g. a game) then you can also switch the challenge UI to match this design choice.


### SDK Events

This SDK allows you to receive interaction events, for your analytics via the `onEvent` method. At the moment the SDK supports:

 - `open`  fires when hCaptcha is opened and a challenge is visible to an app user
 - `expired` fires when the passcode response expires and the user must re-verify
 - `challengeExpired` fires when the user display of a challenge times out with no answer
 - `close` fires when the user dismisses a challenge.
 - `error` fires when an internal error happens during challenge verification, for example a network error. Details about the error will be provided by the `data` param, as in the example below. Note: This event is not intended for error handling, but only for analytics purposes. For error handling please see the `validate` API call docs.

You can check the implementation details in:

- [UIKit Example](./Example/UIKit-Example/README.md)
- [SwiftUI Example](./Example/SwiftUI-Example/README.md)

### Token expiration

Each emitted token has an expiration time. Once this time is reached, you will receive a `.sessionTimeout` error or an `.expired` event in the `onEvent` closure, if it is set.

However, this `error`/`event` will not be emitted in the following cases:

- `HCaptchaResult.dematerialize()` is called; in this case, the token is considered consumed.
- `HCaptcha.stop()` is called; in this case, the SDK stops all processing, and no errors or events will be emitted.

Note that Enterprise customers have additional options: please contact support for guidance if necessary.

### Disable new token fetch on expiry

By default the SDK will automatically fetch a new token upon expiry once you have requested a token via `validate`. This behavior can be adjusted by passing `resetOnError: false` to the `validate` call:

```swift
hcaptcha.validate(on: view, resetOnError: false) { result in
    // Handle result
}
```

### MFA Phone Support

The SDK supports phone prefix and phone number parameters for MFA (Multi-Factor Authentication) flows. You can pass these parameters when calling the `validate` method:

```swift
// Using phone prefix (country code without '+')
let verifyParams = HCaptchaVerifyParams(phonePrefix: "44")
hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
    // Handle result
}

...

// Using phone number (full E.164 format)
let verifyParams = HCaptchaVerifyParams(phoneNumber: "+44123456789")
hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
    // Handle result
}

...

hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
    // Handle result
}
```

**Note**: If you update verify parameters and call `validate` a second time, call `reset()` before the second validation to ensure updated parameters are consumed by the SDK.

### Testing Examples with SPM

If `CocoaPods` for some reason is inaccessible to you, you can test the app with `SPM` only. It will require some changes in the `Xcode` project:

**Note**: Make sure to open `Example/HCaptcha.xcodeproj` and not the workspace file.

In `Xcode`:

1. In `Project Navigator`: from `Frameworks` and Configuration references (red links)
2. Select project (`Project Navigator`) -> Select target (one of our example apps `UIKit-Example` or `SwiftUI-Examples` or another) -> Select `Build Phases` tab -> remove all phases that start with `[CP]` prefix
3. `File` -> `Add Package Dependencies...` -> `Add local...` -> select root of the repo
4. Select project (`Project Navigator`) -> Select target (one of our example apps `UIKit-Example` or `SwiftUI-Examples` or another) -> Select `General` tab -> Go to `Frameworks, Libraries and Embedded Content` -> `+` -> select `HCaptcha`

## Compiled size: impact on including in your app

HCaptcha pod size: **140** KB as of Jan 2024. You can always see the latest number in the CI logs by searching for the "pod size" string.

## Known issues

- WebView crashes on Simulator iOS 14.x (arm64) but not on real devices. [More details](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/103)

## License

HCaptcha is available under the MIT license. See the LICENSE file for more info.


## Troubleshooting

Q. I'm getting a "Could not load embedded HTML" exception. What does this mean?

A. Most likely you have not included an asset in your build. Please double-check assets, and see the example app for more details.


Q. I'm getting "xcconfig: unable to open file" after upgrading the SDK. (Or changing SDK and running Example app.)

A. In your app or the Example app dir, run `pod deintegrate && pod install` to refresh paths.


Q: The challenge modal is displayed, but I can't interact with it. How do I fix this?

A: There are several ways this can happen:

- Your app called [`UIApplication.shared.beginIgnoringInteractionEvents()`](https://developer.apple.com/documentation/uikit/uiapplication/1623047-beginignoringinteractionevents), which prevents any user interaction, before calling the execute method of the SDK. Make sure to call [`UIApplication.shared.endIgnoringInteractionEvents()`](https://developer.apple.com/documentation/uikit/uiapplication/1622938-endignoringinteractionevents) to re-enable interaction before executing the SDK token request if you use this method.

- You may have unintentionally added a transparent overlay over the SDK's view layer. This can be checked with [the view debugger](https://developer.apple.com/documentation/xcode/diagnosing-and-resolving-bugs-in-your-running-app#Inspect-and-resolve-appearance-and-layout-issues)

## Inspiration

Originally forked from fjcaetano's ReCaptcha IOS SDK, licensed under MIT.
