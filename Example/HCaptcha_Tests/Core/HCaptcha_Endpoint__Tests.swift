//
//  HCaptcha_Endpoint__.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 12/07/18.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@testable import HCaptcha
import XCTest

class HCaptcha_Endpoint__Tests: XCTestCase {

    private let endpoint = HCaptcha.Endpoint.default
    private let endpointURL = "https://hcaptcha.com/1/api.js?onload=onloadCallback&render=explicit"

    // MARK: - Locale

    func test__Locale__Nil() {
        XCTAssertEqual(endpoint.getURL(locale: nil), endpointURL)
    }

    func test__Locale__Valid() {
        let locale = Locale(identifier: "pt-BR")
        XCTAssertEqual(endpoint.getURL(locale: locale), "\(endpointURL)&hl=pt-BR")
    }
}
