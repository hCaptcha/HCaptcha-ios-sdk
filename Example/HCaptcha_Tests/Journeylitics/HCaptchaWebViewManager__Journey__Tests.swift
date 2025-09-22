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
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"setData\", token: \"to_be_overwritten\"}")
        manager.completion = { result in
            if let token = result.token, token == "journeys:setData" {
                exp.fulfill()
            }
        }

        let view = UIApplication.shared.windows.first!.rootViewController!.view!
        let journeyJSON = #"[{"k":"click","ts":1,"v":"View","m":{}}]"#
        manager.validate(on: view, journeyEvents: journeyJSON)

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
        let journeyJSON = "korrupted!=!DATA"
        manager.validate(on: view, journeyEvents: journeyJSON)

        wait(for: [exp], timeout: TestTimeouts.standard)
    }
}
