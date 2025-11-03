//
//  HCaptchaWebViewManager+JSCommand.swift
//  HCaptcha
//
//  Copyright © 2025 HCaptcha. All rights reserved.
//

import Foundation

extension HCaptchaWebViewManager {
    enum JSCommand: Equatable {
        case execute(HCaptchaVerifyParams? = nil)
        case reset

        var rawValue: String {
            switch self {
            case .execute(let verifyParams):
                if let verifyParams = verifyParams, let jsonString = verifyParams.toJSONString() {
                    return "execute(\(jsonString));"
                } else {
                    return "execute();"
                }
            case .reset:
                return "reset();"
            }
        }

        static func == (lhs: JSCommand, rhs: JSCommand) -> Bool {
            if case .execute(let lhsParams) = lhs, case .execute(let rhsParams) = rhs {
                return lhsParams?.toJSONString() == rhsParams?.toJSONString()
            } else {
                return lhs.rawValue == rhs.rawValue
            }
        }
    }
}
