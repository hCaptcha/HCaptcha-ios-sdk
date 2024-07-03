# 2.8.0

- Feature: passive site key ([#152](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/152))
- Feature: upgrade Xcode to 15. NOTE: this also increases the minimum supported iOS version to 12. ([#134](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/134))


# 2.7.0

- Fix: don't emit `.sessionTimeout` error once `HCaptchaResult.dematerialize` called ([#129](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/129))
- Fix: keep `.sessionTimeout` as only retriable error to avoid stack overflow

# 2.6.3

- Feature: PrivacyInfo.xcprivacy was added ([#128](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/128))
- Fix: Performance improvements

# 2.6.2

- Feature: new `redrawView` API was added ([#138](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/138))

# 2.5.2

- Fix: disabled controls on visual challenge if validation requested from didFinishLoading

# 2.5.1

- Feature: new `diagnosticLog` argument to enable debug logs.

# 2.5.0

- Feature: new `orientation` argument to set either `.portrait` or `.landscape` challenge orientation.

# 2.4.1

- Fix: release job in CI ([#108](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/108))

# 2.4.0

- Fix: call completion on WebContent process termination
- Added: handle possible WebView navigation errors
- Added: non-blocking initialization path

# 2.3.3

- Fix: Call configureWebView in case if WebView size wasn't changed ([#98](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/98)) ([#91](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/91))
- Fix: open _black links from WebView ([#100](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/100))
- Added pod size diff report ([#96](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/96))
- Added benchmarking for public API ([#95](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/95))

# 2.3.2

- Fix: callback called twice on close error
- Feature: `hcaptcha-form.html` asset moved into a variable

# 2.3.1

- Fix: double call of `completion` for `.challengeClosed` error

# 2.3.0

- Feature: support more events in `onEvent` ([#78](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/78))

# 2.2.0

- Feature: the SDK allows you to receive interaction events for your analytics via the `onEvent` method ([#72](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/72))

# 2.1.1

- Infrastructure: CI now tests example app compilation for both Xcode 12.x and 13.x

# 2.1.0

- Change: you no longer need to set `webview.isHidden = true` on passive sitekeys. The webview is only unhidden if a visual challenge is shown, and `configureWebView` is now called after WebView finishes loading.

# 2.0.0

- **Breaking Change**:  error codes have been renamed and expanded to conform with the Android SDK.
  - renamed: `.responseExpired` -> `.sessionTimeout`
  - renamed:   `.failedRender` -> `.rateLimit`
  - added: `.networkError` ([#41](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/41))

# 1.8.0

- Feature: `Objective-C` support ([#4](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/4))
- Fix: ES5 compliance ([#3](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/3))

# 1.7.0

- Feature: pass `rqdata` to hCaptcha initializer ([#24](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/24))
- Feature: support Swift Package Manager ([#5](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/5))
- Feature: pass `host` to hCaptcha initializer ([#14](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/14))
- Feature: pass `theme`, `customTheme` to hCaptcha initializer ([#27](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/27))

# 1.6.0

- RxSwift 6.2.0

# 1.5.3

- Feature: pass desired checkbox-mode to hCaptcha initializer
- Feature: captcha can be dismissed by tapping outside of it
- Fix: checkbox is centered both vertically and horizontally during presentation
- Change: synced internal error codes with android-sdk
- Change: synced html captcha-container id with android-sdk

# 1.5.2

- Example: cosmetic updates to Example app to handle long passcodes
- Docs: add troubleshooting section

# 1.5.1

- Feature: userClosed error type added
- Docs: explain host override, alternate endpoint use

# 1.5.0

- Swift 5.0 support
- Feature: `didFinishLoading` callback notifier
  
