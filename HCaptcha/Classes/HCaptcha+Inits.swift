//
//  HCaptcha+Inits.swift
//  HCaptcha
//
//  Created by Alex Babrykovich on 22/10/26.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation

extension HCaptcha {
    /**
     - parameter config: SDK init params, see `HCaptchaConfig`

     Initializes a HCaptcha object

     Prefer this init over the one with the long list of params: new params are only added to `HCaptchaConfig`,
     so this signature stays the same between SDK versions.

     - Throws: `HCaptchaError.apiKeyNotFound`: if `config.apiKey` is `nil` and can't find one in the project's
         Info.plist.
     - Throws: `HCaptchaError.baseURLNotFound`: if `config.baseURL` is `nil` and can't find one in the project's
         Info.plist.
     - Throws: `HCaptchaError.invalidCustomTheme`: if `config.customTheme` is not a valid JS object.
     - Throws: `HCaptchaError.invalidHostFormat`: if `config.host` is not a hostname.
     - Throws: `HCaptchaError.journeyliticsNotAvailable`: if `config.userJourney` is set without Journeylitics.
     */
    @objc
    public convenience init(config: HCaptchaConfig) throws {
        Log.minLevel = config.diagnosticLog ? .debug : .warning

        if config.userJourney {
            guard HCaptchaJourneys.start() else { throw HCaptchaError.journeyliticsNotAvailable }
        }

        let infoDict = Bundle.main.infoDictionary

        let plistApiKey = infoDict?[Constants.InfoDictKeys.APIKey] as? String
        let plistDomain = (infoDict?[Constants.InfoDictKeys.Domain] as? String).flatMap(URL.init(string:))

        let resolved = try HCaptchaInternalConfig(apiKey: config.apiKey,
                                                  passiveApiKey: config.passiveApiKey,
                                                  infoPlistKey: plistApiKey,
                                                  baseURL: config.baseURL,
                                                  infoPlistURL: plistDomain,
                                                  jsSrc: config.jsSrc,
                                                  size: config.size,
                                                  orientation: config.orientation,
                                                  rqdata: config.rqdata,
                                                  sentry: config.sentry,
                                                  endpoint: config.endpoint,
                                                  reportapi: config.reportapi,
                                                  assethost: config.assethost,
                                                  imghost: config.imghost,
                                                  host: config.host,
                                                  theme: config.theme,
                                                  customTheme: config.customTheme,
                                                  locale: config.locale,
                                                  disablePat: config.disablePat,
                                                  disableDebugInfo: config.disableDebugInfo,
                                                  userJourney: config.userJourney)

        Log.debug(".init with: \(resolved)")

        self.init(manager: HCaptchaWebViewManager(config: resolved), userJourney: config.userJourney)
    }
}

// Frozen init kept for ABI compatibility with apps and prebuilt frameworks compiled against older SDK versions.
// Don't add params to inits: add new params to `HCaptchaConfig` instead.
extension HCaptcha {
    @objc
    public convenience init(
        apiKey: String?,
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
        disablePat: Bool,
        userJourney: Bool
    ) throws {
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
                      disablePat: disablePat,
                      userJourney: userJourney)
    }
}
