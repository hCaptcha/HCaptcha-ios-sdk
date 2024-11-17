//
//  HCaptcha_UITests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 16/01/18.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation
@testable import HCaptcha
@testable import HCaptcha_UIKit_Example
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
        app.buttons["Validate"].tap()

        let webview = app.staticTexts.element(matching: .any, identifier: "webview")

        XCTAssertTrue(webview.waitForExistence(timeout: 10))
    }
}
