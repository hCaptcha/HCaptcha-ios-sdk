//
//  ViewController.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 03/22/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import HCaptcha
import RxCocoa
import RxSwift
import UIKit
import WebKit

class ViewController: UIViewController {
    private struct Constants {
        static let webViewTag = 123
        static let testLabelTag = 321
    }

    private var hcaptcha: HCaptcha!
    private var disposeBag = DisposeBag()

    private var locale: Locale?

    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var localeSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var validateButton: UIButton!
    @IBOutlet private weak var resetButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        if !Bundle.main.bundlePath.contains("Tests") {
            setupHCaptcha()
        }
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

    // swiftlint:disable function_body_length
    @IBAction private func didPressVerifyButton(button: UIButton) {
        disposeBag = DisposeBag()

        hcaptcha.rx.didFinishLoading
            .debug("did finish loading")
            .subscribe()
            .disposed(by: disposeBag)

        let validate = hcaptcha.rx.validate(on: view, resetOnError: false)
            .catch { error in
                return .just("Error \(error)")
            }
            .debug("validate")
            .share()

        let isLoading = validate
            .map { _ in false }
            .startWith(true)
            .share(replay: 1)

        isLoading
            .bind(to: spinner.rx.isAnimating)
            .disposed(by: disposeBag)

        let isEnabled = isLoading
            .map { !$0 }
            .catchAndReturn(false)
            .share(replay: 1)

        isEnabled
            .bind(to: validateButton.rx.isEnabled)
            .disposed(by: disposeBag)

        validate
            .map { [weak self] _ in
                self?.view.viewWithTag(Constants.webViewTag)
            }
            .subscribe(onNext: { subview in
                subview?.removeFromSuperview()
            })
            .disposed(by: disposeBag)

        validate
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)

        resetButton.rx.tap
            .subscribe(onNext: { [weak hcaptcha] _ in
                hcaptcha?.reset()
            })
            .disposed(by: disposeBag)
    }

    @IBAction private func didPressStopButton(button: UIButton) {
        hcaptcha.stop()
    }

    @IBAction private func didPressResetButton(button: UIButton) {
        hcaptcha?.reset()
    }

    private func setupHCaptcha() {
        // swiftlint:disable:next force_try
        hcaptcha = try! HCaptcha(apiKey: "10000000-ffff-ffff-ffff-000000000001", locale: self.locale, diagnosticLog: true)

        hcaptcha.configureWebView { [weak self] webview in
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
}
