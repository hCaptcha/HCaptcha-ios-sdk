//
//  HCaptchaEvent.swift
//  HCaptcha
//
//  Copyright © 2022 HCaptcha. All rights reserved.
//

import Foundation

/** Events which can be received from HCaptcha SDK
 */
@objc
public enum HCaptchaEvent: Int, RawRepresentable {
    case open
    case expired
    case challengeExpired
    case close

    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .open:
            return "open"
        case .expired:
            return "expired"
        case .challengeExpired:
            return "challengeExpired"
        case .close:
            return "close"
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case "open":
            self = .open
        case "expired":
            self = .expired
        case "challengeExpired":
            self = .challengeExpired
        case "close":
            self = .close
        default:
            return nil
        }
    }

//    public init?(result: HCaptchaDecoder.Result) {
//        switch result {
//        case .onOpen
//            self = .open
//        case .onChallengeExpired
//            self = .challengeExpired
//        case .onExpired
//            self = .expired
//        case .onClose
//            self = .close
//        }
//    }
}
