### SwiftUI Example

Once [installation is complete](../../README.md#installation) and [pre-requisites are met](../../README.md#installation), we are ready to proceed with the actual implementation:

While `HCaptcha` was originally designed for UIKit, you can easily use it with `SwiftUI` as well. Check out the [SwiftUI Example](./ContentView.swift).

To integrate `UIKit` components into a `SwiftUI` project, you can use `UIViewRepresentable`. This protocol allows you to wrap a `UIKit` view and make it compatible with `SwiftUI`. 

For example, to use a `HCaptcha` component (originally designed to show over `UIKit` views) in `SwiftUI`, you would create a `UIViewRepresentable` that provides a "placeholder" view for the `HCaptcha` to be used as host view to add `WKWebView`.

----

[Back to the main README](../../README.md)