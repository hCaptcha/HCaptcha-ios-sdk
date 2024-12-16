## UIKit Example

Once [installation is complete](../../README.md#installation) and [pre-requisites are met](../../README.md#installation), we are ready to proceed with the actual implementation:

``` swift
let hcaptcha = try? HCaptcha()

override func viewDidLoad() {
    super.viewDidLoad()

    hcaptcha?.configureWebView { [weak self] webview in
        webview.frame = self?.view.bounds ?? CGRect.zero
    }
}

// ...

func validate() {
    hcaptcha?.validate(on: view) { [weak self] (result: HCaptchaResult) in
        print(try? result.dematerialize())
    }
}
```

**Note**: caller code is responsible for hiding the `WebView` after challenge processing. This is illustrated in the Example app, and can be achieved with:

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

The full code is in [`ViewContoller.swift`](./ViewContoller.swift)

## Show `hCaptcha` above `UIVisualEffectView`

In case you need to show hCaptcha above `UIVisualEffectView` make sure to pass `visualEffectView.contentView` instead `visualEffectView`. Per Apple's documentation:

> After you add the visual effect view to the view hierarchy, add any subviews to the contentView property of the visual effect view. Do not add subviews directly to the visual effect view itself.

More details [here](https://github.com/hCaptcha/HCaptcha-ios-sdk/issues/50).

## Change hCaptcha frame

If you are customizing display beyond the defaults and need to resize or change the hCaptcha layout, for example after a visual challenge appears, you can use the following approach to trigger a redraw of the view:

``` swift
let hcaptcha = try? HCaptcha(...)
var visualChallengeShown = false
...
hcaptcha?.configureWebView { [weak self] webview in
    webview.tag = "hCaptchaViewTag"
    if visualChallengeShown {
        let padding = 10
        webview.frame = CGRect(
            x: padding,
            y: padding,
            width: view.frame.size.width - 2 * padding,
            height: targetHeight - 2 * padding
        )
    } else {
        webview.frame = self?.view.bounds ?? CGRect.zero
    }
}
...
hcaptcha.onEvent { (event, data) in
    if event == .open {
        visualChallengeShown = true
        hcaptcha.redrawView()
    } else if event == .error {
        let error = data as? HCaptchaError
        print("onEvent error: \(String(describing: error))")
        ...
    }
}
...
hcaptcha.validate(on: view, resetOnError: false) { result in
    visualChallengeShown = false
}
```

## SDK Events

This SDK allows you to receive [interaction events](../../README.md#sdk-events). This is how it can be implemented:

``` swift
let hcaptcha = try? HCaptcha(...)

// ...

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

----

[Back to the main README](../../README.md)