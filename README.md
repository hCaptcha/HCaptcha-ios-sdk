# HCaptcha

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-orange.svg)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/HCaptcha)](http://cocoapods.org/pods/HCaptcha)
[![Platform](https://img.shields.io/badge/Platform-ios-blue)](http://cocoapods.org/pods/HCaptcha)
[![Requirements](https://img.shields.io/badge/iOS-%3E=9.0-blue.svg)](https://developer.apple.com/support/app-store/)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Build](https://github.com/hCaptcha/HCaptcha-ios-sdk/actions/workflows/workflow.yml/badge.svg)](https://github.com/hCaptcha/HCaptcha-ios-sdk/actions/workflows/workflow.yml)

-----

- [HCaptcha](#hcaptcha)
  * [Installation](#installation)
      - [Cocoapods](#cocoapods)
      - [SPM](#spm)
  * [Requirements](#requirements)
  * [Usage](#usage)
      - [Change widget theme](#change-widget-theme)
      - [More params for Enterprise (optional)](#more-params-for-enterprise-optional)
    + [Enabling the visible checkbox flow](#enabling-the-visible-checkbox-flow)
    + [Using landscape instead of portrait orientation](#using-landscape-instead-of-portrait-orientation)
    + [SDK Events](#sdk-events)
  * [Known issues](#known-issues)
  * [License](#license)
  * [Troubleshooting](#troubleshooting)

Add [hCaptcha](https://www.hcaptcha.com/) to your project. This library automatically handles hCaptcha's events and returns a validation token, presenting the challenge via a modal if needed.

#### _Warning_ ⚠️

To secure your application, you need to send the token received here to your backend for server-side validation via the `api.hcaptcha.com/siteverify` endpoint.

## Installation

HCaptcha is available through [CocoaPods](http://cocoapods.org) and packaged for [Carthage](https://github.com/Carthage/Carthage) and [SPM](https://www.swift.org/package-manager/) (Swift Package Manager).

To install it, simply add the following line to your dependencies file:

#### Cocoapods
``` ruby
pod "HCaptcha"
# or
pod "HCaptcha/RxSwift"
```

#### Carthage
``` ruby
github "hCaptcha/HCaptcha-ios-sdk"
```

Carthage will create two different frameworks named `HCaptcha` and `HCaptcha_RxSwift`, the latter containing the RxSwift extension for the HCaptcha framework.

Known issues:
 - Carthage doesn't support prebuilt zips for `xcframework` so use `--no-use-binaries` - https://github.com/Carthage/Carthage/issues/3130
 - Carthage has a `RxSwift` build issue, also avoidable via `--no-use-binaries` - https://github.com/Carthage/Carthage/issues/3243


#### SPM
Standard SPM formula: uses [Package.swift](./Package.swift)

## Requirements

| Platform | Requirements              |
|----------|---------------------------|
| iOS      | :white_check_mark: >= 9.0 |
| WatchOS  | :heavy_multiplication_x:  |

## Usage

hCaptcha sitekeys can be specified as Info.plist keys or can be passed as parameters when instantiating `HCaptcha()`.

For the Info.plist configuration, add `HCaptchaKey` (sitekey) and `HCaptchaDomain` (with a protocol, i.e. https://) to your Info.plist.

- `HCaptchaKey` is your hCaptcha sitekey.
- `HCaptchaDomain` should be a string like `https://www.your.com`
- `baseURL` should match `HCaptchaDomain` if specified; it controls the URI used to initialize the hCaptcha session. Example: `https://www.your.com`

With these values set, run:

``` swift
let hcaptcha = try? HCaptcha()

override func viewDidLoad() {
    super.viewDidLoad()

    hcaptcha?.configureWebView { [weak self] webview in
        webview.frame = self?.view.bounds ?? CGRect.zero
    }
}


func validate() {
    hcaptcha?.validate(on: view) { [weak self] (result: HCaptchaResult) in
        print(try? result.dematerialize())
    }
}
```

**Note**: in case you need to show hCaptcha above `UIVisualEffectView` make sure to pass `visualEffectView.contentView` instead `visualEffectView`. Per Apple's documentation:

> After you add the visual effect view to the view hierarchy, add any subviews to the contentView property of the visual effect view. Do not add subviews directly to the visual effect view itself.

More details [here](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/50).

If you prefer to keep the information out of the Info.plist, you can instead use:

``` swift
let hcaptcha = try? HCaptcha(
    apiKey: "YOUR_HCAPTCHA_KEY", 
    baseURL: URL(string: "YOUR_HCAPTCHA_DOMAIN")!
)

...
```

**Note**: in most cases `baseURL` can be `http://localhost`

You can also install the reactive subpod and use it with RxSwift:

``` swift
hcaptcha.rx.validate(on: view)
    .subscribe(onNext: { (token: String) in
        // Do something
    })
```

Note: caller code is responsible for hiding the `WebView` after challenge processing. This is illustrated in the Example app, and can be achieved with:

1. Regular Swift API:
   ```swift
   ...
   var captchaWebView: WKWebView?
   ...

   hcaptcha?.configureWebView { [weak self] webview in
       self?.captchaWebView = webview
   }
   ...

   hcaptcha.validate(on: view) { result in
       ...

       captchaWebView?.removeFromSuperview()
   }

   ```

1. `RxSwift` API (check [the example](./Example/HCaptcha/ViewController.swift) for more details):
   ```swift
   ...
   hcaptcha?.configureWebView { [weak self] webview in
       webview.tag = "hCaptchaViewTag"
   }
   ...

   let disposeBag = DisposeBag()
   let validate = hcaptcha.rx.validate(on: view)
   ...

   validate
       .map { [weak self] _ in
           self?.view.viewWithTag("hCaptchaViewTag")
       }
       .subscribe(onNext: { webview in
           webview?.removeFromSuperview()
       })
       .disposed(by: disposeBag)
   ```


#### Setting the host override (optional)

Since this SDK uses a local HTML file, you may want to set a host override for better tracking and enforcement of siteverify parameters.

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

#### Change widget theme

The SDK supports three built-in themes: `light`, `dark`, and `contrast`

``` swift
let hcaptcha = try? HCaptcha(
    ...
    theme: "dark", // "light" or "contrast"
    ...
)

...
```

For Enterprise sitekeys we also support custom themes via the `customTheme` parameter, described below.

#### Alternate endpoint (optional)

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

#### More params for Enterprise (optional)

Enterprise params like:

 - `rqdata` (string)
 - `reportapi` (string)
 - `assethost` (string)
 - `imghost` (string)
 - `sentry` (bool)
 - `customTheme` (string representation of JS Object or JSON; see Enterprise docs)

Can be passed via `HCaptcha(...)`

Please see the [hCaptcha Enterprise documentation](https://docs.hcaptcha.com/enterprise/) for more details.

### Enabling the visible checkbox flow

This iOS SDK assumes by default that you want an "invisible" checkbox, i.e. that triggering the hCaptcha flow from within your app should either return a token or show the user a challenge directly.

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

You can implement this with the code below:

``` swift
let hcaptcha = try? HCaptcha(...)
...
hcaptcha.onEvent { (event, data) in
    if event == .open {
        ...
    } else if event == .error {
        let error = data as? HCaptchaError
        print("onEvent error: \(String(describing: error))")
        ...
    }
}
```

For `RxSwift`:

```swift
let hcaptcha = try? HCaptcha(...)
...
hcaptcha.rx.events()
    .subscribe { [weak self] rxevent in
        let event = rxevent.element?.0

        if event == .open {
            ...
        }
    }
    ...
```



### SwiftUI Example

`HCaptcha` was originally designed to be used with UIKit. But you can easily use it with `SwiftUI` as well. Check out the [SwiftUI Example](./Example/SwiftUI)

### Objective-C Example

`HCaptcha` can be used from Objective-C code. Check out the [Example Project](./Example/ObjC)


### Compiled size: impact on including in your app

HCaptcha pod size: **90** KB as of May 16 2022. You can always see the latest number in the CI logs by searching for the "pod size" string.

## Known issues

- WebView crashes on Simulator iOS 14.x (arm64) but not on real devices. [More details](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/103)

## License

HCaptcha is available under the MIT license. See the LICENSE file for more info.


## Troubleshooting

Q. I'm getting a "Could not load embedded HTML" exception. What does it mean?
A. Most likely you have not included an asset in your build. Please double-check this, and see the example app for more details.

Q. I'm getting "xcconfig: unable to open file" after upgrading the SDK. (Or changing SDK and running Example app.)
A: In your app or the Example app dir, run `pod deintegrate && pod install` to refresh paths.


### Inspiration

Originally forked from fjcaetano's ReCaptcha IOS SDK, licensed under MIT.

