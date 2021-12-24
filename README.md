# HCaptcha

<!-- [![Build Status](https://travis-ci.org/hCaptcha/HCaptcha-ios-sdk.svg?branch=master)](https://travis-ci.org/hCaptcha/HCaptcha-ios-sdk) -->
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-orange.svg)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/HCaptcha.svg?style=flat)](http://cocoapods.org/pods/HCaptcha)
[![Platform](https://img.shields.io/cocoapods/p/HCaptcha.svg?style=flat)](http://cocoapods.org/pods/HCaptcha)

-----

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
github "hCaptcha/HCaptcha"
```

#### SPM
Standard SPM formula: uses [Package.swift][./Package.swift]


Carthage will create two different frameworks named `HCaptcha` and `HCaptcha_RxSwift`, the latter containing the RxSwift extension for the HCaptcha framework.

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

If you prefer to keep the information out of the Info.plist, you can instead use:

``` swift
let hcaptcha = try? HCaptcha(
    apiKey: "YOUR_HCAPTCHA_KEY", 
    baseURL: URL(string: "YOUR_HCAPTCHA_DOMAIN")!
)

...
```

You can also install the reactive subpod and use it with RxSwift:

``` swift
hcaptcha.rx.validate(on: view)
    .subscribe(onNext: { (token: String) in
        // Do something
    })
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

```
let hcaptcha = try? HCaptcha(size: .compact)
```

And you will now get the desired behavior.

### SwiftUI Example

`HCaptcha` was originally designed to be used with UIKit. But you can easily use it with `SwiftUI` as well.

```swift

import SwiftUI
import HCaptcha

// Wrapper-view to provide UIView instance
struct UIViewWrapperView : UIViewRepresentable {
    var uiview = UIView()

    func makeUIView(context: Context) -> UIView {
        return uiview
    }

    func updateUIView(_ view: UIView, context: Context) {
    }
}

// Example of hCaptcha usage
struct HCaptchaView: View {
    private(set) var hcaptcha: HCaptcha!

    let placeholder = UIViewWrapperView()

    var body: some View {
        VStack{
            placeholder.frame(width: 400, height: 400, alignment: .center)
            Button(
                "validate",
                action: {
                    hcaptcha.validate(on: placeholder.uiview) { result in
                        print(result)
                    }
                }
            ).padding()
        }
    }


    init() {
        hcaptcha = try! HCaptcha()
        let hostView = self.placeholder.uiview
        hcaptcha.configureWebView { webview in
            webview.frame = hostView.bounds
        }
    }
}

...

```


## License

HCaptcha is available under the MIT license. See the LICENSE file for more info.


## Troubleshooting

Q. I'm getting a "Could not load embedded HTML" exception. What does it mean?
A. Most likely you have not included an asset in your build. Please double-check this, and see the example app for more details.

Q. I'm getting "xcconfig: unable to open file" after upgrading the SDK. (Or changing SDK and running Example app.)
A: In your app or the Example app dir, run `pod deintegrate && pod install` to refresh paths.

### Inspiration

Originally forked from fjcaetano's ReCaptcha IOS SDK, licensed under MIT.

