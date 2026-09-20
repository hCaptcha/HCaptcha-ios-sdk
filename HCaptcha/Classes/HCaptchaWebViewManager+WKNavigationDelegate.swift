//
//  HCaptchaWebViewManager+WKNavigationDelegate.swift
//  HCaptcha
//
//  Copyright © 2024 HCaptcha. All rights reserved.
//

import Foundation
import MessageUI
import WebKit

extension HCaptchaWebViewManager: WKNavigationDelegate, WKUIDelegate, MFMessageComposeViewControllerDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url,
           handleSMSNavigation(for: url) {
            decisionHandler(.cancel)
            return
        }

        if navigationAction.targetFrame == nil, let url = navigationAction.request.url, urlOpener.canOpenURL(url) {
            urlOpener.openURL(url)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            _ = handleSMSNavigation(for: url)
        }
        return nil
    }

    /// Grants the camera capture the liveness challenge requests via `getUserMedia`
    /// (WKWebView auto-denies otherwise). The host app must declare `NSCameraUsageDescription`.
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        // `.cameraAndMicrophone` is intentionally denied alongside `.microphone`: the
        // liveness challenge never requests audio, and granting the microphone would force
        // the host app to declare `NSMicrophoneUsageDescription`, which is not needed.
        let granted = type == .camera
        Log.debug("WebViewManager.requestMediaCapturePermissionFor type: \(type.rawValue) granted: \(granted)")
        decisionHandler(granted ? .grant : .deny)
    }

    /// Tells the delegate that an error occurred during navigation.
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Log.debug("WebViewManager.webViewDidFail with \(error)")
        complete(HCaptchaResult(self, error: .unexpected(error)))
    }

    /// Tells the delegate that an error occurred during the early navigation process.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Log.debug("WebViewManager.webViewDidFailProvisionalNavigation with \(error)")
        complete(HCaptchaResult(self, error: .unexpected(error)))
    }

    /// Tells the delegate that the web view’s content process was terminated.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Log.debug("WebViewManager.webViewWebContentProcessDidTerminate")
        let kHCaptchaErrorWebViewProcessDidTerminate = -1
        let kHCaptchaErrorDomain = "com.hcaptcha.sdk-ios"
        let error = NSError(domain: kHCaptchaErrorDomain,
                            code: kHCaptchaErrorWebViewProcessDidTerminate,
                            userInfo: [
                                NSLocalizedDescriptionKey: "WebView web content process did terminate",
                                NSLocalizedRecoverySuggestionErrorKey: "Call HCaptcha.reset()"])
        didFinishLoading = false
        complete(HCaptchaResult(self, error: .unexpected(error)))
    }

    /// Called when the user taps either Send or Cancel in the composer. Dismissing here returns
    /// the user straight to the challenge, which is still on screen underneath. Re-enabling the
    /// challenge's Confirm button is handled by the hCaptcha web challenge itself.
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        Log.debug("WebViewManager.messageComposeViewController didFinishWith \(result.rawValue)")
        messagePresenter.dismiss(animated: true, completion: nil)
    }
}

// MARK: - SMS Handling

private extension HCaptchaWebViewManager {
    /// Presents the SMS composer in-app when possible, so the user never leaves the host app.
    /// Falls back to the external Messages app whenever the composer is unavailable.
    /// - returns: `true` when the link was handled and the navigation should be cancelled.
    func handleSMSNavigation(for url: URL) -> Bool {
        guard let link = HCaptchaSMSLink(url: url) else { return false }

        if messagePresenter.present(recipient: link.recipient,
                                    body: link.body,
                                    from: webView,
                                    delegate: self) {
            return true
        }

        guard urlOpener.canOpenURL(url) else {
            Log.warn("WebViewManager: cannot handle sms link")
            return false
        }

        Log.debug("WebViewManager: falling back to the external Messages app")
        urlOpener.openURL(url)
        return true
    }
}
