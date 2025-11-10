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
        if let url = navigationAction.request.url,
           handleSMSNavigation(for: url) {
            return nil
        }
        return nil
    }

    /// Tells the delegate that an error occurred during navigation.
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Log.debug("WebViewManager.webViewDidFail with \(error)")
        completion?(HCaptchaResult(self, error: .unexpected(error)))
    }

    /// Tells the delegate that an error occurred during the early navigation process.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Log.debug("WebViewManager.webViewDidFailProvisionalNavigation with \(error)")
        completion?(HCaptchaResult(self, error: .unexpected(error)))
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
        completion?(HCaptchaResult(self, error: .unexpected(error)))
        didFinishLoading = false
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        messagePresenter.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.webView.evaluateJavaScript("window.focus && window.focus();", completionHandler: nil)
        }
    }
}

// MARK: - SMS Handling

private extension HCaptchaWebViewManager {
    func handleSMSNavigation(for url: URL) -> Bool {
        guard url.scheme?.lowercased() == "sms" else { return false }

        let components = parseSMSComponents(from: url)

        if messagePresenter.canSendText(),
           messagePresenter.present(recipient: components.recipient,
                                    body: components.body,
                                    from: webView,
                                    delegate: self) {
            return true
        }

        guard urlOpener.canOpenURL(url) else {
            return false
        }

        urlOpener.openURL(url)
        return true
    }

    func parseSMSComponents(from url: URL) -> (recipient: String?, body: String?) {
        let urlString = url.absoluteString

        guard let schemeRange = urlString.range(of: "sms:", options: [.caseInsensitive, .anchored]) else {
            return (nil, nil)
        }

        let payload = String(urlString[schemeRange.upperBound...])
        let parts = payload.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)

        var recipient = parts.first.map(String.init) ?? ""
        var body: String?

        if parts.count > 1 {
            body = bodyValue(from: String(parts[1]))
        }

        if let delimiterRange = recipient.range(of: ";") {
            let parameters = String(recipient[delimiterRange.lowerBound...])
            recipient = String(recipient[..<delimiterRange.lowerBound])
            if body == nil {
                let query = String(parameters.dropFirst()).replacingOccurrences(of: ";", with: "&")
                body = bodyValue(from: query)
            }
        }

        if let delimiter = recipient.firstIndex(where: { $0 == "," || $0 == "&" }) {
            recipient = String(recipient[..<delimiter])
        }

        recipient = recipient.removingPercentEncoding ?? recipient
        recipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)

        let sanitizedRecipient = recipient
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        return (sanitizedRecipient.isEmpty ? nil : sanitizedRecipient, body)
    }

    func bodyValue(from query: String) -> String? {
        let items = query.split(separator: "&", omittingEmptySubsequences: true)

        for item in items {
            let pair = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard let key = pair.first?.lowercased(), key == "body" else { continue }

            let rawValue = pair.count > 1 ? String(pair[1]) : ""
            return rawValue.removingPercentEncoding ?? rawValue
        }

        return nil
    }
}
