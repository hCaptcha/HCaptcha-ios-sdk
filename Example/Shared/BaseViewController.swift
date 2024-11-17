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

    var hcaptcha: HCaptcha!
    var locale: Locale?

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
