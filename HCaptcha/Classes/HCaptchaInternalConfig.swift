//
//  HCaptchaInternalConfig.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import JavaScriptCore
import UIKit
import WebKit

/** Internal data model: `HCaptchaConfig` resolved against Info.plist and validated
 */
struct HCaptchaInternalConfig: CustomDebugStringConvertible {
    /// The raw unformated HTML file content
    let html: String

    /// The API key that will be sent to the HCaptcha API
    let apiKey: String

    /// For passive apiKeys no user interaction required and HCaptcha stays invisible
    let passiveApiKey: Bool

    /// Size of visible area
    let size: HCaptchaSize

    /// Orientation of widget
    let orientation: HCaptchaOrientation

    /// The base url to be used to resolve relative URLs in the webview
    let baseURL: URL

    /// The url of api.js
    /// Default: https://hcaptcha.com/1/api.js
    let jsSrc: URL

    /// Custom supplied challenge data
    /// - warning: Deprecated. Use `rqdata` in `HCaptchaVerifyParams` instead.
    @available(*, deprecated, message: "Use rqdata in HCaptchaVerifyParams instead")
    let rqdata: String?

    /// Enable / Disable sentry error reporting.
    let sentry: Bool

    /// Point hCaptcha JS Ajax Requests to alternative API Endpoint.
    /// Default: https://hcaptcha.com
    let endpoint: URL?

    /// Point hCaptcha Bug Reporting Request to alternative API Endpoint.
    /// Default: https://accounts.hcaptcha.com
    let reportapi: URL?

    /// Points loaded hCaptcha assets to a user defined asset location, used for proxies.
    /// Default: https://assets.hcaptcha.com
    let assethost: URL?

    /// Points loaded hCaptcha challenge images to a user defined image location, used for proxies.
    /// Default: https://imgs.hcaptcha.com
    let imghost: URL?

    /// SDK's host identifier. nil value means that it will be generated.
    let host: String?

    /// Set the color theme of the widget. Default is "light".
    let theme: String

    /// Custom theme JSON string.
    let customTheme: String?

    /// A locale value to translate HCaptcha into a different language
    let locale: Locale?

    /// A time before throw the `.htmlLoadError` if HCaptcha is not loaded
    let loadingTimeout: TimeInterval

    /// A debug property
    let disablePat: Bool

    /// Disable collection of SDK debug information
    let disableDebugInfo: Bool

    /// Enable user journey tracking for analytics
    let userJourney: Bool

    /// Return actual theme value based on init params. It must return valid JS object.
    var actualTheme: String {
        self.customTheme ?? "\"\(theme)\""
    }

    /// The Bundle that holds HCaptcha's assets
    private static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let bundle = Bundle(for: HCaptcha.self)
        guard let cocoapodsBundle = bundle
                .path(forResource: "HCaptcha", ofType: "bundle")
                .flatMap(Bundle.init(path:)) else {
            return bundle
        }

        return cocoapodsBundle
        #endif
    }()

    var debugDescription: String {
        let mirror = Mirror(reflecting: self)

        var result = "HCaptchaConfig("
        for (label, value) in mirror.children {
            if let label = label, label != "html" {
                result.append("\(label): \(value), ")
            }
        }

        if !mirror.children.isEmpty {
            let lastIndex = result.index(result.endIndex, offsetBy: -2)
            result.removeSubrange(lastIndex...)
        }

        return result + ")"
    }

    /**
     - parameters:
         - config: SDK init params passed to `HCaptcha(config:)`
         - infoPlistKey: The API key retrieved from the application's Info.plist, used if `config.apiKey` is `nil`
         - infoPlistURL: The base URL retrieved from the application's Info.plist, used if `config.baseURL` is `nil`
         - html: The raw unformatted HTML template
         - loadingTimeout: A time before throw the `.htmlLoadError` if HCaptcha is not loaded

     The values are copied, so later changes to `config` don't affect this instance.

     - Throws: `HCaptchaError.apiKeyNotFound`: if an `apiKey` is not provided and can't find one in the project's
     Info.plist.
     - Throws: `HCaptchaError.baseURLNotFound`: if a `baseURL` is not provided and can't find one in the project's
     Info.plist.
     - Throws: `HCaptchaError.invalidCustomTheme`: if `customTheme` is not a valid JS object.
     - Throws: `HCaptchaError.invalidHostFormat`: if `host` is not a hostname.
     */
    init(config: HCaptchaConfig,
         infoPlistKey: String?,
         infoPlistURL: URL?,
         html: String = HCaptchaHtml.template,
         loadingTimeout: TimeInterval = 5.0) throws {
        guard let apiKey = config.apiKey ?? infoPlistKey else {
            throw HCaptchaError.apiKeyNotFound
        }

        guard let domain = config.baseURL ?? infoPlistURL else {
            throw HCaptchaError.baseURLNotFound
        }

        if let customTheme = config.customTheme {
            let validationJS: String = "(function() { return \(customTheme) })()"
            let context = JSContext()!
            context.exceptionHandler = { _, err in
                HCaptchaLogger.error("customTheme validation error: \(String(describing: err))")
            }
            let result = context.evaluateScript(validationJS)
            if result?.isObject != true {
                throw HCaptchaError.invalidCustomTheme
            }
        }

        if let host = config.host, host.localizedStandardContains("/") {
            throw HCaptchaError.invalidHostFormat
        }

        self.html = html
        self.apiKey = apiKey
        self.passiveApiKey = config.passiveApiKey
        self.size = config.size
        self.orientation = config.orientation
        self.baseURL = HCaptchaInternalConfig.fixSchemeIfNeeded(for: domain)
        self.jsSrc = config.jsSrc
        self.rqdata = config.rqdata
        self.sentry = config.sentry
        self.endpoint = config.endpoint
        self.reportapi = config.reportapi
        self.assethost = config.assethost
        self.imghost = config.imghost
        self.host = config.host
        self.theme = config.theme
        self.customTheme = config.customTheme
        self.locale = config.locale
        self.loadingTimeout = loadingTimeout
        self.disablePat = config.disablePat
        self.disableDebugInfo = config.disableDebugInfo
        self.userJourney = config.userJourney
    }

    /**
     The JS API endpoint to be loaded onto the HTML file.
     */
    public var actualEndpoint: URL {
        var result = URLComponents(url: jsSrc, resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "onload", value: "onloadCallback"),
            URLQueryItem(name: "render", value: "explicit"),
            URLQueryItem(name: "recaptchacompat", value: "off"),
            URLQueryItem(name: "host", value: host ?? "\(apiKey).ios-sdk.hcaptcha.com")
        ]

        queryItems.append(URLQueryItem(name: "sentry", value: String(sentry)))
        if let url = endpoint {
            queryItems.append(URLQueryItem(name: "endpoint", value: url.absoluteString))
        }
        if let url = assethost {
            queryItems.append(URLQueryItem(name: "assethost", value: url.absoluteString))
        }
        if let url = imghost {
            queryItems.append(URLQueryItem(name: "imghost", value: url.absoluteString))
        }
        if let url = reportapi {
            queryItems.append(URLQueryItem(name: "reportapi", value: url.absoluteString))
        }
        if let locale = locale {
            queryItems.append(URLQueryItem(name: "hl", value: locale.identifier))
        }
        if customTheme != nil {
            queryItems.append(URLQueryItem(name: "custom", value: String(true)))
        }
        if disablePat {
            queryItems.append(URLQueryItem(name: "pat", value: "off"))
        }

        result.percentEncodedQuery = queryItems.map {
            $0.name +
            "=" +
            $0.value!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
        }.joined(separator: "&")

        return result.url!
    }
}

// MARK: - Private Methods

private extension HCaptchaInternalConfig {
    /**
     - parameter url: The URL to be fixed
     - returns: An URL with scheme

     If the given URL has no scheme, prepends `http://` to it and return the fixed URL.
     */
    static func fixSchemeIfNeeded(for url: URL) -> URL {
        guard url.scheme?.isEmpty != false else {
            return url
        }

        HCaptchaLogger.warn("""
                               ⚠️ WARNING! Protocol not found for HCaptcha domain (\(url))!
                               You should add http:// or https:// to it!
                            """)

        if let fixedURL = URL(string: "http://" + url.absoluteString) {
            return fixedURL
        }

        return url
    }
}
