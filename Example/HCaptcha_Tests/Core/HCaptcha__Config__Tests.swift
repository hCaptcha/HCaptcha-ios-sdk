//
//  HCaptcha__Config__Tests.swift
//  HCaptcha_Tests
//
//  Created by CAMOBAP on 12/20/21.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

import XCTest
import HCaptcha

class HCaptcha__Config__Tests: XCTestCase {
    private let expected = "https://hcaptcha.com/1/api.js?onload=onloadCallback&render=explicit"
        + "&host=ios-sdk.hcaptcha.com&sentry=false&endpoint=https%3A%2F%2Fhcaptcha.com"
        + "&assethost=https%3A%2F%2Fassets.hcaptcha.com&imghost=https%3A%2F%2Fimgs.hcaptcha.com"
        + "&reportapi=https%3A%2F%2Faccounts.hcaptcha.com"

    var config: HCaptcha.Config?

    override func setUpWithError() throws {
        self.config = try? HCaptcha.Config(apiKey: "",
                                           infoPlistKey: nil,
                                           baseURL: URL(string: "https://localhost")!,
                                           infoPlistURL: nil,
                                           size: .invisible,
                                           rqdata: nil,
                                           sentry: false,
                                           apiEndpoint: URL(string: "https://hcaptcha.com/1/api.js")!,
                                           endpoint: URL(string: "https://hcaptcha.com")!,
                                           reportapi: URL(string: "https://accounts.hcaptcha.com")!,
                                           assethost: URL(string: "https://assets.hcaptcha.com")!,
                                           imghost: URL(string: "https://imgs.hcaptcha.com")!)
    }

  func test__Locale__Nil() {
      let actual = config?.getEndpointURL(locale: nil).absoluteString
      XCTAssertEqual(actual, expected)
  }

  func test__Locale__Valid() {
    let actual = config?.getEndpointURL(locale: Locale(identifier: "pt-BR")).absoluteString
    XCTAssertEqual(actual, "\(expected)&hl=pt-BR")
  }

}
