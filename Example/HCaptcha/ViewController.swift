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

class ViewController: UIViewController {
    private struct Constants {
        static let webViewTag = 123
        static let testLabelTag = 321
    }

    private var hcaptcha: HCaptcha!
    private var disposeBag = DisposeBag()

    private var locale: Locale?

    /// Don't init SDK to avoid unnecessary API calls and simplify debugging if the application used as a host for tests
    private var unitTesting: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var localeSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var visibleChallengeSwitch: UISwitch!
    @IBOutlet private weak var validateButton: UIButton!
    @IBOutlet private weak var resetButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHCaptcha()

        if unitTesting {
            validateButton.isEnabled = false
            localeSegmentedControl.isEnabled = false
            visibleChallengeSwitch.isEnabled = false
        }

        resetButton.rx.tap
            .subscribe(onNext: { [weak hcaptcha] _ in
                hcaptcha?.reset()
            })
            .disposed(by: disposeBag)
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
    @IBAction private func didPressButton(button: UIButton) {
        if unitTesting {
            return
        }

        disposeBag = DisposeBag()

        hcaptcha.rx.didFinishLoading
            .debug("did finish loading")
            .subscribe()
            .disposed(by: disposeBag)

        hcaptcha.rx.events()
            .debug("events")
            .subscribe { [weak self] rxevent in
                let event = rxevent.element?.0
                _ = rxevent.element?.1

                let alertController = UIAlertController(title: "On Event",
                                                        message: event?.rawValue,
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
            .bind(to: button.rx.isEnabled)
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

    private func setupHCaptcha() {
        if unitTesting {
            return
        }

        // swiftlint:disable:next force_try
        hcaptcha = try! HCaptcha(locale: locale)

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
