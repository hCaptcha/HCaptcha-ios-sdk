//
//  Result+Helpers.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 13/04/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@testable import HCaptcha


extension HCaptchaResult {
    var token: String? {
        guard case .token(let value) = self else { return nil }
        return value
    }

    var error: HCaptchaError? {
        guard case .error(let error) = self else { return nil }
        return error
    }
}
