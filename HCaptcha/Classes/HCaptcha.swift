//
//  HCaptcha.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import WebKit
import UIKit
import JavaScriptCore

/**
  hCaptcha SDK facade (entry point)
*/
@objc
public class HCaptcha: NSObject {
    struct Constants {
        struct InfoDictKeys {
            static let APIKey = "HCaptchaKey"
            static let Domain = "HCaptchaDomain"
        }
    }

    typealias Log = HCaptchaLogger

    /// The worker that handles webview events and communication
    let manager: HCaptchaWebViewManager

    /// The user journey feature flag
    let userJourney: Bool

    /**
     - parameters:
         - apiKey: The API key sent to the HCaptcha init
         - baseURL: The base URL sent to the HCaptcha init
         - locale: A locale value to translate HCaptcha into a different language
         - size: A HCaptcha size check `HCaptchaSize` for more details
         - orientation: A HCaptcha orientation: `.portrait` or `.landscape` is available
         -  jsSrc: See Enterprise docs
         - rqdata: See Enterprise docs.
         - sentry: See Enterprise docs
         - endpoint: See Enterprise docs
         - reportapi: See Enterprise docs
         - assethost: See Enterprise docs
         - imghost: See Enterprise docs
         - host: See Enterprise docs
         - theme: HCaptcha supports `.light`, `dark` and `.contrast` themes
         - customTheme: See Enterprise docs
         - diagnosticLog: Emit detailed console logs for debugging
         - disableDebugInfo: Disable SDK debug info

     Initializes a HCaptcha object

     Both `apiKey` and `baseURL` may be nil, in which case the lib will look for entries of `HCaptchaKey` and
     `HCaptchaDomain`, respectively, in the project's Info.plist

     - Throws: `HCaptchaError.htmlLoadError`: if is unable to load the HTML embedded in the bundle.
     - Throws: `HCaptchaError.apiKeyNotFound`: if an `apiKey` is not provided and can't find one in the project's
         Info.plist.
     - Throws: `HCaptchaError.baseURLNotFound`: if a `baseURL` is not provided and can't find one in the project's
         Info.plist.
     - Throws: Rethrows any exceptions thrown by `String(contentsOfFile:)`
     */
    @objc
    public convenience init(
        apiKey: String? = nil,
        passiveApiKey: Bool = false,
        baseURL: URL? = nil,
        locale: Locale? = Locale.current,
        size: HCaptchaSize = .invisible,
        orientation: HCaptchaOrientation = .portrait,
        jsSrc: URL = URL(string: "https://js.hcaptcha.com/1/api.js")!,
        rqdata: String? = nil,
        sentry: Bool = false,
        endpoint: URL? = nil,
        reportapi: URL? = nil,
        assethost: URL? = nil,
        imghost: URL? = nil,
        host: String? = nil,
        theme: String = "light",
        customTheme: String? = nil,
        diagnosticLog: Bool = false,
        disableDebugInfo: Bool = false,
        disablePat: Bool = false,
        userJourney: Bool = false
    ) throws {
        let config = HCaptchaConfig()
        config.apiKey = apiKey
        config.passiveApiKey = passiveApiKey
        config.baseURL = baseURL
        config.locale = locale
        config.size = size
        config.orientation = orientation
        config.jsSrc = jsSrc
        config.rqdata = rqdata
        config.sentry = sentry
        config.endpoint = endpoint
        config.reportapi = reportapi
        config.assethost = assethost
        config.imghost = imghost
        config.host = host
        config.theme = theme
        config.customTheme = customTheme
        config.diagnosticLog = diagnosticLog
        config.disableDebugInfo = disableDebugInfo
        config.disablePat = disablePat
        config.userJourney = userJourney

        try self.init(config: config)
    }

    /**
     - parameter manager: A HCaptchaWebViewManager instance.

      Initializes HCaptcha with the given manager
    */
    init(manager: HCaptchaWebViewManager, userJourney: Bool = false) {
        self.manager = manager
        self.userJourney = userJourney
    }

    /**
     - parameter reciever: A callback function

       onEvent allow to subscribe to SDK's events
     */
    @objc
    public func onEvent(_ reciever: ((HCaptchaEvent, Any?) -> Void)? = nil) {
        Log.debug(".onEvent")

        manager.onEvent = reciever
    }

    /**
     - parameters:
         - view: The view that should present the webview.
         - resetOnError: If HCaptcha should be reset if it errors. Defaults to `true`.
         - completion: A closure that receives a HCaptchaResult which may contain a valid result token.

     Starts the challenge validation
     */
    @objc
    public func validate(on view: UIView? = nil, resetOnError: Bool = true,
                         completion: @escaping (HCaptchaResult) -> Void) {
        Log.debug(".validate on: \(String(describing: view)) resetOnError: \(resetOnError)")

        if userJourney {
            let verifyParams = HCaptchaVerifyParams(resetOnError: resetOnError)
            verifyParams.userJourney = HCaptchaJourneys.drainEvents()
            manager.verifyParams = verifyParams
        } else {
            manager.verifyParams = nil
        }
        manager.shouldResetOnError = resetOnError
        manager.completion = completion
        manager.validate(on: view)
    }

    /**
     - parameters:
         - view: The view that should present the webview.
         - verifyParams: Parameters supplied at verification time (e.g., phone prefix/number for MFA flows).
         - completion: A closure that receives a HCaptchaResult which may contain a valid result token.

     Starts the challenge validation with verification parameters
     */
    @objc
    public func validate(on view: UIView? = nil, verifyParams: HCaptchaVerifyParams,
                         completion: @escaping (HCaptchaResult) -> Void) {
        Log.debug(".validate on: \(String(describing: view)) verifyParams: \(verifyParams)")

        if userJourney {
            verifyParams.userJourney = HCaptchaJourneys.drainEvents()
        }

        guard verifyParams.hasSupportedValues || verifyParams.userJourney != nil else {
            manager.verifyParams = nil
            completion(HCaptchaResult(manager, error: .verifyParamsParseError))
            return
        }

        manager.completion = completion
        manager.verifyParams = verifyParams
        manager.shouldResetOnError = verifyParams.resetOnError

        manager.validate(on: view)
    }

    /// Stops the execution of the webview
    @objc
    public func stop() {
        Log.debug(".stop")
        HCaptchaJourneys.stop()
        manager.stop()
    }


    /**
     - parameter configure: A closure that receives an instance of `WKWebView` for configuration.

     Provides a closure to configure the webview for presentation if necessary.

     If presentation is required, the webview will already be a subview of `presenterView` if one is provided. Otherwise
     it might need to be added in a view currently visible.
    */
    @objc
    public func configureWebView(_ configure: @escaping (WKWebView) -> Void) {
        Log.debug(".configureWebView")

        manager.configureWebView = configure
    }

    /**
     Resets the HCaptcha.

     The reset is achieved by calling `hcaptcha.reset()` on the JS API.
    */
    @objc
    public func reset() {
        Log.debug(".reset")

        manager.reset()
    }

    /**
     - parameter closure: A closure that is called when the JS bundle finishes loading.

     Provides a closure to be notified when the webview finishes loading JS resources.

     The closure may be called multiple times since the resources may also be loaded multiple times
     in case of error or reset. This may also be immediately called if the resources have already
     finished loading when you set the closure.
    */
    @objc
    public func didFinishLoading(_ closure: (() -> Void)?) {
        Log.debug(".didFinishLoading")
        manager.onDidFinishLoading = closure
    }

    /**
     Request for a call to the `configureWebView` closure.

     This may be useful if you need to modify the layout of hCaptcha.
    */
    @objc
    public func redrawView() {
        manager.configureWebView?(manager.webView)
    }

    // MARK: - Objective-C 'convenience' inits

    @objc
    public convenience init(locale: Locale) throws {
        let config = HCaptchaConfig()
        config.locale = locale
        try self.init(config: config)
    }

    @objc
    public convenience init(size: HCaptchaSize) throws {
        let config = HCaptchaConfig()
        config.locale = nil
        config.size = size
        try self.init(config: config)
    }

    @objc
    public convenience init(passiveApiKey: Bool) throws {
        let config = HCaptchaConfig()
        config.locale = nil
        config.passiveApiKey = passiveApiKey
        try self.init(config: config)
    }

    @objc
    public convenience init(apiKey: String) throws {
        let config = HCaptchaConfig(apiKey: apiKey)
        config.locale = nil
        try self.init(config: config)
    }

    @objc
    public convenience init(apiKey: String, baseURL: URL) throws {
        let config = HCaptchaConfig(apiKey: apiKey, baseURL: baseURL)
        config.locale = nil
        try self.init(config: config)
    }

    @objc
    public convenience init(apiKey: String, passiveApiKey: Bool) throws {
        let config = HCaptchaConfig(apiKey: apiKey)
        config.locale = nil
        config.passiveApiKey = passiveApiKey
        try self.init(config: config)
    }

    @objc
    public convenience init(apiKey: String, baseURL: URL, locale: Locale) throws {
        let config = HCaptchaConfig(apiKey: apiKey, baseURL: baseURL)
        config.locale = locale
        try self.init(config: config)
    }

    @objc
    public convenience init(apiKey: String, baseURL: URL, locale: Locale, size: HCaptchaSize) throws {
        let config = HCaptchaConfig(apiKey: apiKey, baseURL: baseURL)
        config.locale = locale
        config.size = size
        try self.init(config: config)
    }

    @objc
    public convenience init(apiKey: String?,
                            passiveApiKey: Bool,
                            baseURL: URL?,
                            locale: Locale?,
                            size: HCaptchaSize,
                            orientation: HCaptchaOrientation,
                            jsSrc: URL,
                            rqdata: String?,
                            sentry: Bool,
                            endpoint: URL?,
                            reportapi: URL?,
                            assethost: URL?,
                            imghost: URL?,
                            host: String?,
                            theme: String,
                            customTheme: String?,
                            diagnosticLog: Bool,
                            userJourney: Bool) throws {
        try self.init(apiKey: apiKey,
                      passiveApiKey: passiveApiKey,
                      baseURL: baseURL,
                      locale: locale,
                      size: size,
                      orientation: orientation,
                      jsSrc: jsSrc,
                      rqdata: rqdata,
                      sentry: sentry,
                      endpoint: endpoint,
                      reportapi: reportapi,
                      assethost: assethost,
                      imghost: imghost,
                      host: host,
                      theme: theme,
                      customTheme: customTheme,
                      diagnosticLog: diagnosticLog,
                      disableDebugInfo: false,
                      disablePat: false,
                      userJourney: userJourney)
    }
}
