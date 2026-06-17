//
//  HCaptchaWebViewManager+WKNavigationDelegate.swift
//  HCaptcha
//
//  Copyright © 2024 HCaptcha. All rights reserved.
//

import Foundation
import WebKit

extension HCaptchaWebViewManager: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url, urlOpener.canOpenURL(url) {
            urlOpener.openURL(url)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, url.scheme == "sms" && urlOpener.canOpenURL(url) {
            urlOpener.openURL(url)
        }
        return nil
    }

    /// Grants camera capture requested via `getUserMedia` by the hCaptcha content loaded
    /// in this web view (the camera-based liveness challenge). Without this, WKWebView
    /// auto-denies the request and the camera challenge cannot start.
    ///
    /// Only camera capture is granted — the liveness challenge requests video only.
    ///
    /// The host app must still declare `NSCameraUsageDescription` in its Info.plist;
    /// iOS terminates the app on camera access otherwise.
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
}
