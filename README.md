# HCaptcha

<!-- [![Build Status](https://travis-ci.org/hCaptcha/HCaptcha-ios-sdk.svg?branch=master)](https://travis-ci.org/hCaptcha/HCaptcha-ios-sdk) -->
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-orange.svg)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/HCaptcha.svg?style=flat)](http://cocoapods.org/pods/HCaptcha)
[![Platform](https://img.shields.io/cocoapods/p/HCaptcha.svg?style=flat)](http://cocoapods.org/pods/HCaptcha)

-----

Add [hCaptcha](https://www.hcaptcha.com/) to your project. This library
automatically handles hCaptcha's events and retrieves the validation token or notifies you to present the challenge if
invisibility is not possible.


#### _Warning_ ⚠️

To properly secure your application, you will still need to send the token received here to your server for server-side validation via the `siteverify` endpoint on hcaptcha.com.

## Installation

HCaptcha may eventually be available through [CocoaPods](http://cocoapods.org) and [Carthage](https://github.com/Carthage/Carthage).

It is currently packaged for both.

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

Carthage will create two different frameworks named `HCaptcha` and `HCaptcha_RxSwift`, the latter containing the RxSwift
extension for the HCaptcha framework.

## Usage

The hCaptcha keys can be specified as Info.plist keys or can be passed as parameters when instantiating HCaptcha().

For the Info.plist configuration, add `HCaptchaKey` and `HCaptchaDomain` (with a protocol ex. http:// or https://) to your Info.plist and run:

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

If instead you prefer to keep the information out of the Info.plist, you can use:
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

#### Setting the host override

Since this SDK uses a local HTML file, you will want to set a host override for better tracking and enforcement of siteverify parameters.

In HCaptcha/Classes/HCaptcha.swift, change:

``` swift
let jsargs = "?onload=onloadCallback&render=explicit&host=ios-sdk.hcaptcha.com"
```

to:

``` swift
let jsargs = "?onload=onloadCallback&render=explicit&host=ios-sdk.YOUR-DOMAIN.com"
```


#### Alternate endpoint

If you are an Enterprise user with first-party hosting access, you will need to set your own endpoint.

You can then enable it in your code:

``` swift
public enum Endpoint {
    case default, alternate
}

let hcaptcha = try? HCaptcha(endpoint: .alternate) // Defaults to `default` when unset
```

after setting your URI in HCaptcha/Classes/HCaptcha.swift: `altjsurl` variable.


### Enabling the visible checkbox flow

This iOS SDK assumes by default that you want an "invisible" checkbox, i.e. that triggering the hCaptcha flow from within your app should either return a token or show the user a challenge directly.

If you instead want the classic "normal" or "compact" checkbox behavior of showing a checkbox to tick and then either closing or showing a challenge, you can pass `size` to HCaptcha initializer.

```
let hcaptcha = try? HCaptcha(size: .compact)
```

And you will now get the desired behavior.


## License

HCaptcha is available under the MIT license. See the LICENSE file for more info.


## Troubleshooting

Q. I'm getting a "Could not load embedded HTML" exception. What does it mean?
A. Most likely you have not included an asset in your build. Please double-check this, and see the example app for more details.

Q. I'm getting "xcconfig: unable to open file" after upgrading the SDK. (Or changing SDK and running Example app.)
A: In your app or the Example app dir, run `pod deintegrate && pod install` to refresh paths.

## Inspiration

Originally forked from fjcaetano's ReCaptcha IOS SDK, licensed under MIT.

