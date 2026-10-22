//
//  HCaptchaInternalConfig+Helpers.swift
//  HCaptcha_Tests
//
//  Created by Алексей Берёзка on 17.08.2021.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

import Foundation
@testable import HCaptcha

extension HCaptchaInternalConfig {
    init(html: String = HCaptchaHtml.template,
         apiKey: String? = String(arc4random()),
         passiveApiKey: Bool = false,
         infoPlistKey: String? = "api-key",
         baseURL: URL? = URL(string: "http://localhost")!,
         infoPlistURL: URL? = nil,
         size: HCaptchaSize = .invisible,
         orientation: HCaptchaOrientation = .portrait,
         rqdata: String? = nil,
         endpoint: URL = URL(string: "https://api.hcaptcha.com")!,
         host: String? = nil,
         theme: String = "light",
         customTheme: String? = nil,
         locale: Locale? = nil,
         loadingTimeout: TimeInterval = 5.0,
         disablePat: Bool = false,
         disableDebugInfo: Bool = false,
         userJourney: Bool = false) throws {
        let config = HCaptchaConfig()
        config.apiKey = apiKey
        config.passiveApiKey = passiveApiKey
        config.baseURL = baseURL
        config.jsSrc = URL(string: "https://hcaptcha.com/1/api.js")!
        config.size = size
        config.orientation = orientation
        config.rqdata = rqdata
        config.endpoint = endpoint
        config.reportapi = URL(string: "https://accounts.hcaptcha.com")!
        config.assethost = URL(string: "https://newassets.hcaptcha.com")!
        config.imghost = URL(string: "https://imgs.hcaptcha.com")!
        config.host = host
        config.theme = theme
        config.customTheme = customTheme
        config.locale = locale
        config.disablePat = disablePat
        config.disableDebugInfo = disableDebugInfo
        config.userJourney = userJourney

        try self.init(config: config,
                      infoPlistKey: infoPlistKey,
                      infoPlistURL: infoPlistURL,
                      html: html,
                      loadingTimeout: loadingTimeout)
    }

    init(apiKey: String = "some-api-key",
         host: String? = nil,
         customTheme: String? = nil,
         locale: Locale? = nil) throws {
        try self.init(apiKey: apiKey,
                      infoPlistKey: nil,
                      baseURL: URL(string: "https://localhost")!,
                      infoPlistURL: nil,
                      host: host,
                      customTheme: customTheme,
                      locale: locale)
    }
}
