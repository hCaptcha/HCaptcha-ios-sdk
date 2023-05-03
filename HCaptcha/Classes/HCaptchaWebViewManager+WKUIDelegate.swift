//
//  HCaptchaWebViewManager+WKNavigationDelegate.swift
//  HCaptcha
//
//  Copyright © 2023 HCaptcha. All rights reserved.
//

import Foundation
import WebKit

extension HCaptchaWebViewManager: WKUIDelegate {

    /// To handle window.open() calls
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            urlOpener.openURL(url)
        }
        return nil
    }
}
