//
//  BaseViewController.swift
//  HCaptcha
//
//  Copyright © 2024 HCaptcha. All rights reserved.
//

import HCaptcha
import UIKit
import WebKit

class BaseViewController: UIViewController {
    struct Constants {
        static let webViewTag = 123
        static let testLabelTag = 321
    }

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var localeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var validateButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!

    // Phone input UI elements - connected from storyboard
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var phoneModeSwitch: UISwitch!
    @IBOutlet weak var phoneModeLabel: UILabel!

    var hcaptcha: HCaptcha!
    var locale: Locale?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPhoneInputUI()
        setupToolbar()
        if !Bundle.main.bundlePath.contains("Tests") {
            setupHCaptcha()
        }
    }

    private func setupToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneTapped))
        toolbar.items = [done]
        phoneTextField.inputAccessoryView = toolbar
    }

    @objc private func doneTapped() {
        phoneTextField.resignFirstResponder()
    }

    private func setupPhoneInputUI() {
        phoneModeSwitch.isOn = false
        phoneModeChanged(phoneModeSwitch)
    }

    @IBAction func phoneModeChanged(_ sender: UISwitch) {
        if sender.isOn {
            phoneModeLabel.text = "Number"
            phoneTextField.placeholder = "Enter phone number (e.g., +1234567890)"
            phoneTextField.keyboardType = .phonePad
        } else {
            phoneModeLabel.text = "Prefix"
            phoneTextField.placeholder = "Enter prefix (e.g., 44)"
            phoneTextField.keyboardType = .numberPad
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

    @IBAction func didPressStopButton(button: UIButton) {
        hcaptcha.stop()
    }

    @IBAction func didPressResetButton(button: UIButton) {
        hcaptcha.reset()
    }

    func setupHCaptcha() {
        fatalError("This method must be overridden by a subclass")
    }
}
