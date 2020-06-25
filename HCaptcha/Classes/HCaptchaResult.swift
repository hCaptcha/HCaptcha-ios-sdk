//
//  HCaptchaWebViewManager.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 06/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation

/** The HCaptcha result.

 This may contain the validation token on success, or an error that may have occurred.
 */
public enum HCaptchaResult {
    /// The validation token.
    case token(String)

    /// An error that may have occurred.
    case error(HCaptchaError)

    /**
     - returns: The validation token uppon success.

     Tries to unwrap the Result and retrieve the token if it's successful.

     - Throws: `HCaptchaError`
     */
    public func dematerialize() throws -> String {
        switch self {
        case .token(let token):
            return token

        case .error(let error):
            throw error
        }
    }
}
