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
  
