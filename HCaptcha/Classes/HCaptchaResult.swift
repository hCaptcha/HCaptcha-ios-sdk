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
@objc
public class HCaptchaResult: NSObject {

    /// Result token
    let token: String?

    /// Result error
    let error: HCaptchaError?

    public init (token: String? = nil, error: HCaptchaError? = nil) {
        self.token = token
        self.error = error
    }

    /**
     - returns: The validation token uppon success.

     Tries to unwrap the Result and retrieve the token if it's successful.

     - Throws: `HCaptchaError`
     */
    @objc
    public func dematerialize() throws -> String {
        if let token = self.token {
            return token
        }

        if let error = self.error {
            throw error
        }

        assertionFailure("Impossible state result must be initialized with token or error")
        return ""
    }
}
