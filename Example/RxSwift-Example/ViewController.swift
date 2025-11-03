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

    @IBAction private func didPressVerifyButton(button: UIButton) {
        disposeBag = DisposeBag()
        setupLoadingObservable()
        let validate = createValidateObservable()
        setupUIBindings(validate: validate)
        setupResetButton()
    }

    private func setupLoadingObservable() {
        hcaptcha.rx.didFinishLoading
            .debug("did finish loading")
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func createValidateObservable() -> Observable<String> {
        if let phoneText = phoneTextField.text, !phoneText.isEmpty {
            return createPhoneValidateObservable(phoneText: phoneText)
        } else {
            return createRegularValidateObservable()
        }
    }

    private func createPhoneValidateObservable(phoneText: String) -> Observable<String> {
        let verifyParams: HCaptchaVerifyParams
        if phoneModeSwitch.isOn {
            // Phone number mode
            verifyParams = HCaptchaVerifyParams(phoneNumber: phoneText, rqdata: "some_rq")
        } else {
            // Phone prefix mode
            verifyParams = HCaptchaVerifyParams(phonePrefix: phoneText)
        }

        return hcaptcha.rx.validate(on: view, verifyParams: verifyParams)
            .catch { error in
                return .just("Error \(error)")
            }
            .debug("validate with phone params")
            .share()
    }

    private func createRegularValidateObservable() -> Observable<String> {
        return hcaptcha.rx.validate(on: view, resetOnError: false)
            .catch { error in
                return .just("Error \(error)")
            }
            .debug("validate")
            .share()
    }

    private func setupUIBindings(validate: Observable<String>) {
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
    }

    private func setupResetButton() {
        resetButton.rx.tap
            .subscribe(onNext: { [weak hcaptcha] _ in
                hcaptcha?.reset()
            })
            .disposed(by: disposeBag)
    }


    override func setupHCaptcha() {
        // swiftlint:disable:next force_try
        hcaptcha = try! HCaptcha(
            apiKey: "00000000-0000-0000-0000-000000000000",
            locale: locale,
            diagnosticLog: true,
            userJourneys: journeySwitch.isOn
        )

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
