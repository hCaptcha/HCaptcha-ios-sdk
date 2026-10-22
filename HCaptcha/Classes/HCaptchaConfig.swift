//
//  HCaptchaConfig.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation

/** Widget display mode
 */
@objc
public enum HCaptchaSize: Int, RawRepresentable {
    case invisible
    case compact
    case normal

    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .invisible:
            return "invisible"
        case .compact:
            return "compact"
        case .normal:
            return "normal"
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case "invisible":
            self = .invisible
        case "compact":
            self = .compact
        case "normal":
            self = .normal
        default:
            return nil
        }
    }
}

/** Widget orientation mode
 */
@objc
public enum HCaptchaOrientation: Int, RawRepresentable {
    case portrait
    case landscape

    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .portrait:
            return "portrait"
        case .landscape:
            return "landscape"
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case "portrait":
            self = .portrait
        case "landscape":
            self = .landscape
        default:
            return nil
        }
    }
}

/**
 SDK init params passed to `HCaptcha(config:)`

 New params are added here as properties with default values, so the `HCaptcha(config:)` signature never changes
 and adding a param does not break apps or prebuilt frameworks compiled against an older SDK version.

 The values are read once in `HCaptcha(config:)`; changing them afterwards does not affect that `HCaptcha` instance.

 - Warning: `HCaptchaConfig` is not thread-safe. Don't mutate it from another thread while `HCaptcha(config:)` runs.
 */
@objc
public final class HCaptchaConfig: NSObject {
    /// The API key sent to the HCaptcha init. If `nil`, `HCaptchaKey` from Info.plist is used
    @objc public var apiKey: String?

    /// For passive apiKeys no user interaction required and HCaptcha stays invisible
    @objc public var passiveApiKey: Bool = false

    /// The base URL sent to the HCaptcha init. If `nil`, `HCaptchaDomain` from Info.plist is used
    @objc public var baseURL: URL?

    /// A locale value to translate HCaptcha into a different language
    @objc public var locale: Locale? = Locale.current

    /// A HCaptcha size check `HCaptchaSize` for more details
    @objc public var size: HCaptchaSize = .invisible

    /// A HCaptcha orientation: `.portrait` or `.landscape` is available
    @objc public var orientation: HCaptchaOrientation = .portrait

    /// See Enterprise docs
    @objc public var jsSrc: URL = URL(string: "https://js.hcaptcha.com/1/api.js")!

    /// See Enterprise docs
    @objc public var sentry: Bool = false

    /// See Enterprise docs
    @objc public var endpoint: URL?

    /// See Enterprise docs
    @objc public var reportapi: URL?

    /// See Enterprise docs
    @objc public var assethost: URL?

    /// See Enterprise docs
    @objc public var imghost: URL?

    /// See Enterprise docs
    @objc public var host: String?

    /// HCaptcha supports `light`, `dark` and `contrast` themes
    @objc public var theme: String = "light"

    /// See Enterprise docs
    @objc public var customTheme: String?

    /// Emit detailed console logs for debugging
    @objc public var diagnosticLog: Bool = false

    /// Disable SDK debug info
    @objc public var disableDebugInfo: Bool = false

    /// A debug property
    @objc public var disablePat: Bool = false

    /// Enable user journey tracking for analytics, requires `HCaptcha/Journeylitics`
    @objc public var userJourney: Bool = false

    /// Deprecated init-time `rqdata`, kept only for the legacy `HCaptcha.init(...rqdata:...)` path.
    /// New code passes `rqdata` via `HCaptchaVerifyParams`
    var rqdata: String?

    @objc
    override public init() {
        super.init()
    }

    @objc
    public convenience init(apiKey: String) {
        self.init()
        self.apiKey = apiKey
    }

    @objc
    public convenience init(apiKey: String, baseURL: URL) {
        self.init(apiKey: apiKey)
        self.baseURL = baseURL
    }
}
