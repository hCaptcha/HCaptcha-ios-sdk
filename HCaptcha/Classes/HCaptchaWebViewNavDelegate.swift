//
//  HCaptchaWebViewNavDelegate.swift
//  HCaptcha
//
//  Copyright © 2022 HCaptcha. All rights reserved.
//

import Foundation
import WebKit
import WultraSSLPinning

class HCaptchaWebViewNavDelegate: UIResponder, WKNavigationDelegate {
    fileprivate static var certStore: CertStore {
        let publicKey = "BO47Jqs1wXV9dt1q1hMHuZzUPVzGNaPn9vUqRzleMiHAIYg+zZmktobi3nKVrtExIctL9f8aTdpfwhex21jbI9g="
        let config = CertStoreConfiguration(serviceUrl: URL(string: "https://hcaptcha.com")!,
                                            publicKey: publicKey)
        return .powerAuthCertStore(configuration: config)
    }

    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch HCaptchaWebViewNavDelegate.certStore.validate(challenge: challenge) {
        case .trusted:
            completionHandler(.performDefaultHandling, nil)
        case .untrusted, .empty:
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
