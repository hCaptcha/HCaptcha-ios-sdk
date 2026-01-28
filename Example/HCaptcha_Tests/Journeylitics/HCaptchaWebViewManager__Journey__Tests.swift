//
//  HCaptcha__Journey__Tests.swift
//  HCaptcha_Tests
//
//  Copyright © 2025 HCaptcha. All rights reserved.
//

@testable import HCaptcha
import XCTest

class HCaptcha__Journey__Tests: XCTestCase {
    func test__setData_called_injects_journeys() {
        let exp = expectation(description: "journeys setData -> token posted")
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"setData\", token: \"journeys:setData\"}")
        manager.completion = { result in
            if let token = result.token, token == "journeys:setData" {
                exp.fulfill()
            }
        }

        let view = UIApplication.shared.windows.first!.rootViewController!.view!
        // Create journey events as raw data (array of dictionaries)
        let journeyEvents: [Any] = [["k": "click", "ts": 1, "v": "View", "m": [:]]]
        let verifyParams = HCaptchaVerifyParams(userJourney: journeyEvents)
        manager.verifyParams = verifyParams
        manager.validate(on: view)

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__setData_failed() {
        let exp = expectation(description: "journeys setData -> token posted")
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"setData\", token: \"fallback_token\"}")
        manager.completion = { result in
            if let token = result.token, token == "fallback_token" {
                exp.fulfill()
            }
        }

        let view = UIApplication.shared.windows.first!.rootViewController!.view!
        // Create invalid journey events data to test error handling
        let invalidJourneyEvents: [Any] = ["korrupted!=!DATA"]
        let verifyParams = HCaptchaVerifyParams(userJourney: invalidJourneyEvents)
        manager.verifyParams = verifyParams
        manager.validate(on: view)

        wait(for: [exp], timeout: TestTimeouts.standard)
    }
}
