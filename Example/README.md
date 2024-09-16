# HCaptcha Example App

This app is designed to let you quickly experiment with HCaptcha SDK options.

You can also simply copy the example code in the ViewController to get up and running quickly in your own app.


## Quickstart: Building the Example

If you don't already have a working CocoaPods environment, we recommend homebrew:

`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

Then install CocoaPods:

`brew install cocoapods`

Finally, install the pods needed for the Example app:

`pod install`


You should now be able to build and run the example in Xcode.


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
