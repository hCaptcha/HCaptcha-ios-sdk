//
//  TestMessagePresenter.swift
//  HCaptcha
//
//

@testable import HCaptcha

import MessageUI
import UIKit
import XCTest

final class TestMessagePresenter: HCaptchaMessagePresenter {
    var shouldPresentSucceed: Bool = true

    var presentExpectation: XCTestExpectation?
    var dismissExpectation: XCTestExpectation?

    private(set) var lastRecipient: String?
    private(set) var lastBody: String?
    private(set) weak var lastDelegate: MFMessageComposeViewControllerDelegate?

    private(set) var dismissCallCount: Int = 0

    func present(recipient: String?, body: String?, from sourceView: UIView,
                 delegate: MFMessageComposeViewControllerDelegate) -> Bool {
        lastRecipient = recipient
        lastBody = body
        lastDelegate = delegate
        presentExpectation?.fulfill()
        return shouldPresentSucceed
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        dismissCallCount += 1
        dismissExpectation?.fulfill()
        completion?()
    }

    func resetExpectations() {
        presentExpectation = nil
        dismissExpectation = nil
    }
}
