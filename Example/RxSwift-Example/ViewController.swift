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

class ViewController: BaseViewController {
    var disposeBag = DisposeBag()

    // Phone input UI elements - connected from storyboard
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var phoneModeSwitch: UISwitch!
    @IBOutlet weak var phoneModeLabel: UILabel!

    @IBAction private func didPressVerifyButton(button: UIButton) {
        disposeBag = DisposeBag()

        hcaptcha.rx.didFinishLoading
            .debug("did finish loading")
            .subscribe()
            .disposed(by: disposeBag)

        // Create validate observable based on phone input
        let validate: Observable<String>
        if let phoneText = phoneTextField.text, !phoneText.isEmpty {
            let verifyParams: HCaptchaVerifyParams
            if phoneModeSwitch.isOn {
                // Phone number mode
                verifyParams = HCaptchaVerifyParams(phoneNumber: phoneText)
            } else {
                // Phone prefix mode
                verifyParams = HCaptchaVerifyParams(phonePrefix: phoneText)
            }

            validate = hcaptcha.rx.validate(on: view, verifyParams: verifyParams)
                .catch { error in
                    return .just("Error \(error)")
                }
                .debug("validate with phone params")
                .share()
        } else {
            // Regular validation without phone params
            validate = hcaptcha.rx.validate(on: view, resetOnError: false)
                .catch { error in
                    return .just("Error \(error)")
                }
                .debug("validate")
                .share()
        }

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPhoneInputUI()
    }

    private func setupPhoneInputUI() {
        // Configure initial state
        phoneModeLabel.text = "Prefix"
        phoneTextField.placeholder = "Enter phone prefix (e.g., 44)"
        phoneTextField.keyboardType = .numberPad
    }

    @IBAction private func phoneModeChanged(_ sender: UISwitch) {
        if phoneModeSwitch.isOn {
            phoneModeLabel.text = "Phone"
            phoneTextField.placeholder = "Enter phone number (e.g., +1234567890)"
            phoneTextField.keyboardType = .phonePad
        } else {
            phoneModeLabel.text = "Prefix"
            phoneTextField.placeholder = "Enter phone prefix (e.g., 44)"
            phoneTextField.keyboardType = .numberPad
        }
    }

    override func setupHCaptcha() {
        // swiftlint:disable:next force_try
        hcaptcha = try! HCaptcha(apiKey: "00000000-0000-0000-0000-000000000000", locale: locale, diagnosticLog: true)

        hcaptcha.configureWebView { [weak self] webview in
            webview.frame = self?.view.bounds ?? CGRect.zero
            webview.tag = Constants.webViewTag

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
