//
//  HCaptchaError.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation

/// The codes of possible errors thrown by HCaptcha
public enum HCaptchaError: Error, CustomStringConvertible {

    /// Unexpected error
    case unexpected(Error)

    /// Could not load the HTML embedded in the bundle
    case htmlLoadError

    /// HCaptchaKey was not provided
    case apiKeyNotFound

    /// HCaptchaDomain was not provided
    case baseURLNotFound

    /// Received an unexpected message from javascript
    case wrongMessageFormat

    /// HCaptcha setup failed
    case failedSetup

    /// HCaptcha response expired
    case responseExpired

    /// user closed HCaptcha without answering
    case userClosed

    /// HCaptcha render failed
    case failedRender

    /// Invalid custom theme passed
    case invalidCustomTheme

    public static func == (lhs: HCaptchaError, rhs: HCaptchaError) -> Bool {
        return lhs.description == rhs.description
    }

    /// A human-readable description for each error
    public var description: String {
        switch self {
        case .unexpected(let error):
            return "Unexpected Error: \(error)"

        case .htmlLoadError:
            return "Could not load embedded HTML"

        case .apiKeyNotFound:
            return "HCaptchaKey not provided"

        case .baseURLNotFound:
            return "HCaptchaDomain not provided"

        case .wrongMessageFormat:
            return "Unexpected message from javascript"

        case .failedSetup:
            return """
            ⚠️ WARNING! HCaptcha wasn't successfully configured. Please double check your HCaptchaKey and HCaptchaDomain.
            Also check that you're using HCaptcha's **SITE KEY** for client side integration.
            """

        case .responseExpired:
            return "Response expired and need to re-verify"

        case .userClosed:
            return "User closed challenge without answering"

        case .failedRender:
            return "HCaptcha encountered an error in execution"

        case .invalidCustomTheme:
            return "Invalid JSON or JSObject as customTheme"
        }
    }
}
