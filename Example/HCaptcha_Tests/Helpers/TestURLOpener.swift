//
//  TestURLOpener.swift
//  HCaptcha
//
//  Copyright © 2025 HCaptcha. All rights reserved.
//

@testable import HCaptcha

import XCTest

class TestURLOpener: HCaptchaURLOpener {
    private let canOpenExpectation: XCTestExpectation
    private let openExpectation: XCTestExpectation

    init(_ canOpen: XCTestExpectation, _ open: XCTestExpectation) {
        self.canOpenExpectation = canOpen
        self.openExpectation = open
    }

    func canOpenURL(_ url: URL) -> Bool {
        canOpenExpectation.fulfill()
        return true
    }

    func openURL(_ url: URL) {
        openExpectation.fulfill()
    }
}
