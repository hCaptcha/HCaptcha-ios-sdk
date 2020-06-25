# HCaptcha

[![Build Status](https://travis-ci.org/hCaptcha/HCaptcha.svg?branch=master)](https://travis-ci.org/hCaptcha/HCaptcha)
[![codecov](https://codecov.io/gh/hCaptcha/HCaptcha/branch/master/graph/badge.svg)](https://codecov.io/gh/hCaptcha/HCaptcha)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/hCaptcha/HCaptcha/pulls)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-orange.svg)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/HCaptcha.svg?style=flat)](http://cocoapods.org/pods/HCaptcha)
[![License](https://img.shields.io/cocoapods/l/HCaptcha.svg?style=flat)](http://cocoapods.org/pods/HCaptcha)
[![Platform](https://img.shields.io/cocoapods/p/HCaptcha.svg?style=flat)](http://cocoapods.org/pods/HCaptcha)

-----

Add [hCaptcha](https://www.hcaptcha.com/) to your project. This library
automatically handles hCaptcha's events and retrieves the validation token or notifies you to present the challenge if
invisibility is not possible.


#### _Warning_ ⚠️

To properly secure your application, you will still need to send the token received here to your server for server-side validation via the `siteverify` endpoint on hcaptcha.com.

## Installation

HCaptcha is available through [CocoaPods](http://cocoapods.org) and [Carthage](https://github.com/Carthage/Carthage).
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

#### Alternate endpoint

If you are an Enterprise user with first-party hosting access, you will need to set your own endpoint.

You can then enable it in your code:

``` swift
public enum Endpoint {
    case default, alternate
}

let hcaptcha = try? HCaptcha(endpoint: .alternate) // Defaults to `default` when unset
```

## Help Wanted

Do you love hCaptcha and work actively on apps that use it? We'd love if you could help us keep improving it!
Feel free to message us or to start contributing right away!

## [Full Documentation](http://hCaptcha.github.io/HCaptcha)

## License

HCaptcha is available under the MIT license. See the LICENSE file for more info.

## Inspiration

Originally built on fjcaetano's  ReCaptcha IOS SDK, licensed under MIT.

