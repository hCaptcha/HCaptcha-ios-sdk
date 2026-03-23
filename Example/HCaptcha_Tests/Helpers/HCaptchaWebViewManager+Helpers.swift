//
//  HCaptchaWebViewManager+Helpers.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 13/04/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation
@testable import HCaptcha
import WebKit

extension HCaptchaWebViewManager {
    private static let unformattedHTML: String! = {
        Bundle(for: HCaptchaWebViewManager__Tests.self)
            .path(forResource: "mock", ofType: "html")
            .flatMap { try? String(contentsOfFile: $0) }
    }()

    enum MockOnLoad: String {
        case didLoad
        case networkError
        case networkOnce
    }

    convenience init(
        messageBody: String = "undefined",
        apiKey: String? = nil,
        passiveApiKey: Bool = false,
        endpoint: URL? = nil,
        onLoad: MockOnLoad = .didLoad,
        shouldFail: Bool = false,
        size: HCaptchaSize = .invisible,
        rqdata: String? = nil,
        theme: String = "light",
        customTheme: String? = nil,
        userJourney: Bool = false,
        urlOpener: HCaptchaURLOpener = HCapchaAppURLOpener()
    ) {
        let onExecute = shouldFail ? "sessionTimeout" : "normal"
        let html = String(format: HCaptchaWebViewManager.unformattedHTML,
                          arguments: [
                            "message": messageBody,
                            "onLoad": onLoad.rawValue,
                            "onExecute": onExecute
                          ])

        self.init(
            html: html,
            apiKey: apiKey ?? "api-key",
            passiveApiKey: passiveApiKey,
            endpoint: endpoint ?? URL(string: "https://api.hcaptcha.com")!,
            size: size,
            rqdata: rqdata,
            theme: theme,
            customTheme: customTheme,
            urlOpener: urlOpener,
            userJourney: userJourney
        )
    }

    convenience init(
        html: String,
        apiKey: String,
        passiveApiKey: Bool = false,
        endpoint: URL = URL(string: "https://api.hcaptcha.com")!,
        size: HCaptchaSize = .invisible,
        orientation: HCaptchaOrientation = .portrait,
        rqdata: String? = nil,
        theme: String = "light",
        customTheme: String? = nil,
        urlOpener: HCaptchaURLOpener = HCapchaAppURLOpener(),
        loadingTimeout: TimeInterval = 5,
        userJourney: Bool = false
    ) {
        let localhost = URL(string: "http://localhost")!

        // swiftlint:disable:next force_try
        let config = try! HCaptchaConfig(html: html,
                                         apiKey: apiKey,
                                         passiveApiKey: passiveApiKey,
                                         baseURL: localhost,
                                         size: size,
                                         orientation: orientation,
                                         rqdata: rqdata,
                                         endpoint: endpoint,
                                         theme: theme,
                                         customTheme: customTheme,
                                         loadingTimeout: loadingTimeout,
                                         disablePat: nil,
                                         userJourney: userJourney)

        self.init(
            config: config,
            urlOpener: urlOpener
        )
    }

    func configureWebView(_ configure: @escaping (WKWebView) -> Void) {
        configureWebView = configure
    }

    func validate(on view: UIView, resetOnError: Bool = true, completion: @escaping (HCaptchaResult) -> Void) {
        self.verifyParams = nil
        self.shouldResetOnError = resetOnError
        self.completion = completion

        validate(on: view)
    }

    /// Removes all session/local storage from the default data store so
    /// tests start with a clean `WKWebView` environment.
    static func clearWebViewData() {
        let types: Set<String> = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeLocalStorage
        ]
        var done = false
        WKWebsiteDataStore.default().removeData(
            ofTypes: types,
            modifiedSince: .distantPast
        ) { done = true }
        while !done {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
    }
}
