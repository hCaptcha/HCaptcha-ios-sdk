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
                      rqdata: nil)
    }
}
