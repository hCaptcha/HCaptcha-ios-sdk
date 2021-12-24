//
//  HCaptcha__Config__Tests.swift
//  HCaptcha_Tests
//
//  Created by CAMOBAP on 12/20/21.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

@testable import HCaptcha
import XCTest

class HCaptcha__Config__Tests: XCTestCase {
    private let expected = "https://hcaptcha.com/1/api.js?onload=onloadCallback&render=explicit&recaptchacompat=off"
        + "&host=some-api-key.ios-sdk.hcaptcha.com&sentry=false&endpoint=https%3A%2F%2Fapi.hcaptcha.com"
        + "&assethost=https%3A%2F%2Fnewassets.hcaptcha.com&imghost=https%3A%2F%2Fimgs.hcaptcha.com"
        + "&reportapi=https%3A%2F%2Faccounts.hcaptcha.com"

    var config: HCaptcha.Config?

    func createConfig(apiKey: String = "some-api-key",
                      host: String? = nil,
                      customTheme: String? = nil) -> HCaptcha.Config? {
        return try? HCaptcha.Config(apiKey: apiKey,
                                    infoPlistKey: nil,
                                    baseURL: URL(string: "https://localhost")!,
                                    infoPlistURL: nil,
                                    host: host,
                                    customTheme: customTheme)
    }


    func test__Locale__Nil() {
        let config = createConfig()
        let actual = config?.getEndpointURL().absoluteString
        XCTAssertEqual(actual, expected)
    }

    func test__Locale__Valid() {
        let locale = "pt-BR"
        let config = createConfig()
        let actual = config?.getEndpointURL(locale: Locale(identifier: locale)).absoluteString
        XCTAssertEqual(actual, "\(expected)&hl=\(locale)")
    }

    func test__Custom__Host() {
        let host = "custom-host"
        let config = createConfig(host: host)
        let actual = config?.getEndpointURL().absoluteString
        XCTAssertEqual(actual, expected.replacingOccurrences(
            of: "some-api-key.ios-sdk.hcaptcha.com",
            with: host))
    }

    func test__Custom__Theme() {
        let cusomtTheme = """
          {
            primary: {
              main: "#00FF00"
            },
            text: {
              heading: "#454545",
              body   : "#8C8C8C"
            }
          }
        """
        let config = createConfig(customTheme: cusomtTheme)
        let actual = config?.getEndpointURL().absoluteString
        XCTAssertEqual(actual, expected + "&custom=true")
    }
}
