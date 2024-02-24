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
    private var challengeShown: Bool = false

    /// Don't init SDK to avoid unnecessary API calls and simplify debugging if the application used as a host for tests
    private var unitTesting: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var localeSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var apiSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var visibleChallengeSwitch: UISwitch!
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
        if self.apiSegmentedControl.selectedSegmentIndex == 0 {
            self.verifyRxApi()
        } else {
            self.verifyRegularApi()
        }
    }

    private func verifyRegularApi() {
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

    // swiftlint:disable function_body_length
    private func verifyRxApi() {
        disposeBag = DisposeBag()

        hcaptcha.rx.didFinishLoading
            .debug("did finish loading")
            .subscribe()
            .disposed(by: disposeBag)

        hcaptcha.rx.events()
            .debug("events")
            .subscribe { [weak self] (event, data) in
                if event == .error {
                    let error = data as? HCaptchaError
                    print("onEvent error: \(String(describing: error))")
                }

                if event == .open {
                    self?.challengeShown = true
                    /// redrawView call is not required, included for demo purposes
                    self?.hcaptcha.redrawView()
                }

                let alertController = UIAlertController(title: "On Event",
                                                        message: event.rawValue,
                                                        preferredStyle: .alert)
                self?.present(alertController, animated: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        alertController.dismiss(animated: true, completion: nil)
                    }
                }
            }
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
                self.challengeShown = false
                subview?.removeFromSuperview()
            })
            .disposed(by: disposeBag)

        validate
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)

        visibleChallengeSwitch.rx.value
            .subscribe(onNext: { [weak hcaptcha] value in
                hcaptcha?.forceVisibleChallenge = value
            })
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
        if unitTesting {
            return
        }

        // swiftlint:disable:next force_try
        hcaptcha = try! HCaptcha(locale: locale)

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
