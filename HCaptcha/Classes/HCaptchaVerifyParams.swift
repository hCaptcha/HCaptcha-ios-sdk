//
//  HCaptchaVerifyParams.swift
//  HCaptcha
//
//  Created by Assistant on 26/09/25.
//  Copyright © 2025 HCaptcha. All rights reserved.
//

import Foundation

/**
 Parameters supplied at verification time.
 */
@objc
public class HCaptchaVerifyParams: NSObject {

    /**
     Optional phone country calling code (without '+'), e.g., "44".
     Used in MFA flows.
     */
    @objc public let phonePrefix: String?

    /**
     Optional full phone number in E.164 format. Used in MFA flows.
     */
    @objc public let phoneNumber: String?

    /**
     Optional request data string to be passed to hCaptcha.
     */
    @objc public let rqdata: String?

    /**
     If HCaptcha should be reset if it errors. Defaults to `true`.
     */
    @objc public let resetOnError: Bool

    /**
     Optional user journey events for analytics tracking.
     */
    @objc internal var userJourney: Any?

    /**
     - parameters:
     - phonePrefix: Optional phone country calling code (without '+'), e.g., "44"
     - phoneNumber: Optional full phone number in E.164 or local format
     - rqdata: Optional request data string to be passed to hCaptcha
     - userJourney: Optional user journey events for analytics tracking (Any type that will be JSON serialized)
     - resetOnError: If HCaptcha should be reset if it errors. Defaults to `true`

     Initializes HCaptchaVerifyParams with the given parameters.
     */
    @objc
    internal init(phonePrefix: String?,
                  phoneNumber: String?,
                  rqdata: String?,
                  userJourney: Any?,
                  resetOnErr: Bool) {
        self.phonePrefix = phonePrefix
        self.phoneNumber = phoneNumber
        self.rqdata = rqdata
        self.userJourney = userJourney
        self.resetOnError = resetOnErr
    }

    internal convenience init(phonePrefix: String? = nil,
                              phoneNumber: String? = nil,
                              rqdata: String? = nil,
                              userJourney: Any? = nil,
                              resetOnError: Bool = true) {
        self.init(
            phonePrefix: phonePrefix,
            phoneNumber: phoneNumber,
            rqdata: rqdata,
            userJourney: userJourney,
            resetOnErr: resetOnError
        )
    }

    /**
     Convenience initializer for backward compatibility (without userJourney parameter)
     */
    public convenience init(phonePrefix: String? = nil,
                            phoneNumber: String? = nil,
                            rqdata: String? = nil,
                            resetOnError: Bool = true) {
        self.init(
            phonePrefix: phonePrefix,
            phoneNumber: phoneNumber,
            rqdata: rqdata,
            userJourney: nil,
            resetOnErr: resetOnError
        )
    }

    /**
     - returns: A dictionary representation of the verify params for JSON serialization
     */
    @objc
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let phonePrefix = phonePrefix {
            dict["mfa_phoneprefix"] = phonePrefix
        }
        if let phoneNumber = phoneNumber {
            dict["mfa_phonenumber"] = phoneNumber
        }
        if let rqdata = rqdata {
            dict["rqdata"] = rqdata
        }
        if let userJourney = userJourney {
            dict["userJourney"] = userJourney
        }
        dict["resetOnError"] = resetOnError
        return dict
    }

    /**
     - returns: A JSON string representation of the verify params
     */
    @objc
    public func toJSONString() -> String? {
        let dict = toDictionary()
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}
