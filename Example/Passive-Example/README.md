## Passive ApiKey Example

Make sure [installation is complete](../../README.md#installation) and [pre-requisites are met](../../README.md#installation)

HCaptcha Enterprise supports verification with no interaction from the user: [Passive Site Keys](https://docs.hcaptcha.com/faq#what-are-the-difficulty-levels-for-the-challenges-and-how-are-they-selected).

Using the `passiveApiKey` option with Passive sitekeys provides performance improvements in SDK token generation time, at the cost of less flexibility if you want to change the sitekey mode in the future without a code update.

The full code is in [Example](./ContentView.swift).

----

[Back to the main README](../../README.md)