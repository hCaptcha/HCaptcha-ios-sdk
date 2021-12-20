//
//  HCaptchaConfig+Helpers.swift
//  HCaptcha_Tests
//
//  Created by Алексей Берёзка on 17.08.2021.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

import Foundation
@testable import HCaptcha

extension HCaptcha.Config {
    init(apiKey: String?,
         infoPlistKey: String?,
         baseURL: URL?,
         infoPlistURL: URL?) throws {
        try self.init(apiKey: apiKey,
                      infoPlistKey: infoPlistKey,
                      baseURL: baseURL,
                      infoPlistURL: infoPlistURL,
                      size: .invisible,
                      rqdata: nil,
                      sentry: false,
                      apiEndpoint: URL(string: "https://hcaptcha.com/1/api.js")!,
                      endpoint: URL(string: "https://hcaptcha.com")!,
                      reportapi: URL(string: "https://accounts.hcaptcha.com")!,
                      assethost: URL(string: "https://assets.hcaptcha.com")!,
                      imghost: URL(string: "https://imgs.hcaptcha.com")!
        )
    }
}
