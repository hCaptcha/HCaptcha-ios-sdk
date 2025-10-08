//
//  ViewController.swift
//  HCaptacha_UIKitExample
//
//  Copyright © 2024 HCaptcha. All rights reserved.
//

import HCaptcha
import UIKit
import WebKit

class ViewController: BaseViewController {
    private var challengeShown: Bool = false

    @IBAction private func didPressVerifyButton(button: UIButton) {
        // Check if we should use verify params
        if let phoneText = phoneTextField.text, !phoneText.isEmpty {
            let verifyParams: HCaptchaVerifyParams
            if phoneModeSwitch.isOn {
                // Phone number mode
                verifyParams = HCaptchaVerifyParams(phoneNumber: phoneText)
            } else {
                // Phone prefix mode
                verifyParams = HCaptchaVerifyParams(phonePrefix: phoneText)
            }

            hcaptcha.validate(on: self.view, verifyParams: verifyParams) { result in
                self.handleResult(result)
            }
        } else {
            // Regular validation without phone params
            hcaptcha.validate(on: self.view) { result in
                self.handleResult(result)
            }
        }
    }

    private func handleResult(_ result: HCaptchaResult) {
        do {
            self.label.text = try result.dematerialize()
        } catch let error as HCaptchaError {
            self.label.text = error.description
        } catch let error {
            self.label.text = String(describing: error)
        }
        let subview = self.view.viewWithTag(Constants.webViewTag)
        subview?.removeFromSuperview()
        self.challengeShown = false
    }


    override func setupHCaptcha() {
        // swiftlint:disable:next force_try
        hcaptcha = try! HCaptcha(apiKey: "00000000-0000-0000-0000-000000000000", locale: locale, diagnosticLog: true)

        hcaptcha.onEvent { (event, _) in
            if event == .open {
                let webview = self.view.viewWithTag(Constants.webViewTag)!
                self.moveHCaptchaUp(webview)
            }
        }

        hcaptcha.configureWebView { [weak self] webview in
            webview.frame = self?.view.bounds ?? CGRect.zero
            webview.tag = Constants.webViewTag

            // could use this option if using an enterprise passive sitekey:
            // webview.isHidden = true
            // seems to prevent flickering on latest iOS 15.2
            webview.isOpaque = false
            webview.backgroundColor = UIColor.clear
            webview.scrollView.backgroundColor = UIColor.clear
        }
    }

    /**
     Move hCaptcha WebView frame to the top part of the screen
    */
    private func moveHCaptchaUp(_ webview: UIView) {
        let padding: CGFloat = 0
        let windowHeight = view.frame.size.height
        let targetHeight = (2.0 / 3.0) * windowHeight

        webview.frame = CGRect(
            x: padding,
            y: padding,
            width: view.frame.size.width - 2 * padding,
            height: targetHeight - 2 * padding
        )
    }
}
