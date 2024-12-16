## Objective-C Example

Make sure [installation is complete](../../README.md#installation) and [pre-requisites are met](../../README.md#installation)

`HCaptcha` exposes its API to real native code, so it can be used from `Objective-C`.

Because `HCaptcha` is a pure Swift library, it exposes its API through the `@objc` attribute.

The `@objc` attribute makes Swift methods, properties, and classes available to Objective-C code. By marking a Swift method or class with `@objc`, it is automatically bridged to Objective-C, allowing for interoperability between Swift and Objective-C. 

Also because `Objective-C` doesn't support optional arguments, the most popular constructors of `HCaptcha` are available in `Objective-C`

The full code is in [ViewController.m](./ViewController.m).

----

[Back to the main README](../../README.md)