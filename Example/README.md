# HCaptcha Example App

This app is designed to let you quickly experiment with HCaptcha SDK options.

You can also simply copy the example code in the ViewController to get up and running quickly in your own app.


## Quickstart: Building the Example

1. Open `Example/HCaptcha.xcodeproj` in Xcode.
2. Let SPM resolve RxSwift. The SDK is linked from the local repository.
3. Select `HCaptcha-UIKit-Example`, `HCaptcha-RxSwift-Example`, `HCaptcha-Objc-Example`, `HCaptcha-SwiftUI-Example`, or `HCaptcha-Passive-Example`.
4. Select a simulator or device, then build and run.

From the repository root, run tests with `bundle exec fastlane test` and build all samples with `bundle exec fastlane samples_build`.

## Example Changes

### Switching to a Visible Checkbox

You can try switching the 'size' parameter or any other by editing Example/HCaptcha/ViewController.swift

For example:

```
@@ -175,7 +176,7 @@ class ViewController: UIViewController {
         }

         // swiftlint:disable:next force_try
-        hcaptcha = try! HCaptcha(locale: locale)
+        hcaptcha = try! HCaptcha(locale: locale, size: .normal)
```

Tapping "Validate" will now show a visible checkbox, which can be tapped to continue the interaction.

### Changing the Example Sitekey

This example app sets the sitekey in Example/HCaptcha/Info.plist via the `HCaptchaKey` field.

You can replace it with your own sitekey to try a different sitekey configuration, e.g. Passive mode.
