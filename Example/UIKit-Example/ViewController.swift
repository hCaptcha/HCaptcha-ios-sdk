//
//  ViewController.swift
//  HCaptacha_UIKitExample
//
//  Copyright © 2024 HCaptcha. All rights reserved.
//

import HCaptcha
import UIKit
import WebKit

class ViewController: UIViewController {
    private struct Constants {
        static let webViewTag = 123
        static let testLabelTag = 321
    }

    private var hcaptcha: HCaptcha!

    private var locale: Locale?
    private var challengeShown: Bool = false

    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var localeSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var validateButton: UIButton!
    @IBOutlet private weak var resetButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHCaptcha()
    }

    @IBAction func didPressLocaleSegmentedControl(_ sender: UISegmentedControl) {
        label.text = ""
        switch sender.selectedSegmentIndex {
        case 0: locale = nil
        case 1: locale = Locale(identifier: "zh-CN")
        default: assertionFailure("invalid index")
        }

        setupHCaptcha()
    }

    @IBAction private func didPressVerifyButton(button: UIButton) {
        hcaptcha.validate(on: self.view) { result in
            do {
                self.label.text = try result.dematerialize()
            } catch let error as HCaptchaError {
                self.label.text = error.description
            } catch let error {
                self.label.text = String(describing: error)
            }
            let subview = self.view.viewWithTag(Constants.webViewTag)
            subview?.removeFromSuperview()
        }
    }

    @IBAction private func didPressStopButton(button: UIButton) {
        hcaptcha.stop()
    }

    @IBAction private func didPressResetButton(button: UIButton) {
        hcaptcha?.reset()
    }

    private func setupHCaptcha() {
        // swiftlint:disable:next force_try
        hcaptcha = try! HCaptcha(apiKey: "00000000-0000-0000-0000-000000000000", locale: self.locale, diagnosticLog: true)

        hcaptcha.configureWebView { [weak self] webview in
            if self?.challengeShown == true {
                self?.moveHCaptchaUp(webview)
                return
            }
            webview.frame = self?.view.bounds ?? CGRect.zero
            webview.tag = Constants.webViewTag

            // could use this option if using an enterprise passive sitekey:
            // webview.isHidden = true
            // seems to prevent flickering on latest iOS 15.2
            webview.isOpaque = false
            webview.backgroundColor = UIColor.clear
            webview.scrollView.backgroundColor = UIColor.clear
            // For testing purposes
            // If the webview requires presentation, this should work as a way of detecting the webview in UI tests
            self?.view.viewWithTag(Constants.testLabelTag)?.removeFromSuperview()
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            label.tag = Constants.testLabelTag
            label.accessibilityLabel = "webview"
            self?.view.addSubview(label)
        }
    }

    /**
     Move hCaptcha WebView frame to the top part of the screen
    */
    private func moveHCaptchaUp(_ webview: WKWebView) {
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

