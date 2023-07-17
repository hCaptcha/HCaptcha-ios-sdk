---
name: Bug report
about: Create a report to help us improve
---
## Before opening an issue, check the following:
1. You are using the **SITE** key.
2. The correct domain, with protocol, is set up.
3. You are using an **hCaptcha** key. It does **NOT** start with 0x. That's a secret key.
4. If the widget doesn't appear, that is expected since the library will try to resolve the challenge _invisibly_.

## Bug description
A clear and concise description of what the bug is.

## To Reproduce
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. ...

## Debug Logs

The `HCaptcha` constructor accepts a `diagnosticLog` flag (bool) to enable detailed SDK logs. If you would like to report an issue with the SDK, please enable this flag and attach `diagnosticLog` output when you open the issue.

## Expected behavior
A clear and concise description of what you expected to happen.

## Logs
Please add as many logs as you feel necessary. Be mindful of your application and remove any sensitive data.

## Additional context
Add any other context about the problem here.
