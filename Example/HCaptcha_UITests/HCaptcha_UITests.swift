//
//  HCaptcha_UITests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 16/01/18.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation
@testable import HCaptcha
@testable import HCaptcha_Example
import XCTest

class HCaptcha_UITests: XCTestCase {

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    func test__Simple__Validate__Rx() {
        let app = XCUIApplication()
        app.segmentedControls.buttons["Rx"].tap()
        app.buttons["Validate"].tap()

        verifyValidation()
    }

    func test__Simple__Validate__Regular() {
        let app = XCUIApplication()
        app.segmentedControls.buttons["Regular"].tap()
        app.buttons["Validate"].tap()

        verifyValidation()
    }

    // MARK: Private Methods

    private func verifyValidation() {
        let app = XCUIApplication()
        let webview = app.staticTexts.element(matching: .any, identifier: "webview")

        XCTAssertTrue(webview.waitForExistence(timeout: 10))
    }
}
