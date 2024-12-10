## RxSwift Example

Once [installation is complete](../../README.md#installation) and [pre-requisites are met](../../README.md#installation), we are ready to proceed with the actual implementation:

``` swift
var hcaptcha: HCaptcha!

// ...

hcaptcha.rx.validate(on: view)
    .subscribe(onNext: { (token: String) in
        // Do something
    })
```

Note: caller code is responsible for hiding the `WebView` after challenge processing. This is illustrated in the Example app, and can be achieved with:

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

The full code is in [`ViewController.swift`](./ViewController.swift)

### SDK Events

This SDK allows you to receive [interaction events](../../README.md#sdk-events). This is how it can be implemented:

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

----

[Back to the main README](../../README.md)