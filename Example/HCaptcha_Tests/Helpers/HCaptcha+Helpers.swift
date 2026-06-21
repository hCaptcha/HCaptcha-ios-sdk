//
//  HCaptcha+Helpers.swift
//  HCaptcha_Tests
//
//  Copyright © 2026 HCaptcha. All rights reserved.
//

import Foundation
@testable import HCaptcha

extension HCaptcha {
    /// Test-only convenience init that defaults `userJourney` to false.
    convenience init(manager: HCaptchaWebViewManager) {
        self.init(manager: manager, userJourney: false)
    }
}
