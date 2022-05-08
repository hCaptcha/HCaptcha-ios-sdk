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

    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .open:
            return "open"
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case "open":
            self = .open
        default:
            return nil
        }
    }
}
