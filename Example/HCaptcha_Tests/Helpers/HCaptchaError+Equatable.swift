//
//  HCaptchaError+Equatable.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 16/10/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation
@testable import HCaptcha

extension HCaptchaError: Equatable {
    public static func == (lhs: HCaptchaError, rhs: HCaptchaError) -> Bool {
        switch (lhs, rhs) {
        case (.htmlLoadError, .htmlLoadError),
             (.apiKeyNotFound, .apiKeyNotFound),
             (.baseURLNotFound, .baseURLNotFound),
             (.wrongMessageFormat, .wrongMessageFormat),
             (.failedSetup, .failedSetup),
             (.sessionTimeout, .sessionTimeout),
             (.rateLimit, .rateLimit),
             (.invalidCustomTheme, .invalidCustomTheme),
             (.networkError, .networkError),
             (.invalidHostFormat, .invalidHostFormat),
             (.journeyliticsNotAvailable, .journeyliticsNotAvailable):
            return true
        case (.unexpected(let lhe as NSError), .unexpected(let rhe as NSError)):
            return lhe == rhe
        default:
            return false
        }
    }

    static func random() -> HCaptchaError {
        let cases: [HCaptchaError] = [
            .htmlLoadError,
            .apiKeyNotFound,
            .baseURLNotFound,
            .wrongMessageFormat,
            .failedSetup,
            .sessionTimeout,
            .rateLimit,
            .invalidCustomTheme,
            .invalidHostFormat,
            .networkError,
            .journeyliticsNotAvailable,
            .unexpected(NSError())
        ]
        return cases.randomElement()!
    }
}
