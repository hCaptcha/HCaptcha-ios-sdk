//
//  HCaptchaWebViewManager.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation
import WebKit


/** Handles comunications with the webview containing the HCaptcha challenge.
 */
internal class HCaptchaWebViewManager: NSObject {
    enum JSCommand: String {
        case execute = "execute();"
        case reset = "reset();"
    }

    fileprivate struct Constants {
        static let ExecuteJSCommand = "execute();"
        static let ResetCommand = "reset();"
        static let BotUserAgent = "bot/2.1"
    }

#if DEBUG
    /// Forces the challenge to be explicitly displayed.
    var forceVisibleChallenge = false {
        didSet {
            // Also works on iOS < 9
            webView.performSelector(
                onMainThread: "_setCustomUserAgent:",
                with: forceVisibleChallenge ? Constants.BotUserAgent : nil,
                waitUntilDone: true
            )
        }
    }

    /// Allows validation stubbing for testing
    public var shouldSkipForTests = false
#endif

    /// Sends the result message
    var completion: ((HCaptchaResult) -> Void)?

    /// Called (currently) when a challenge becomes visible
    var onEvent: ((HCaptchaEvent, Any?) -> Void)?

    /// Notifies the JS bundle has finished loading
    var onDidFinishLoading: (() -> Void)? {
        didSet {
            if didFinishLoading {
                onDidFinishLoading?()
            }
        }
    }

    /// Configures the webview for display when required
    var configureWebView: ((WKWebView) -> Void)?

    /// The dispatch token used to ensure `configureWebView` is only called once.
    var configureWebViewDispatchToken = UUID()

    /// If the HCaptcha should be reset when it errors
    var shouldResetOnError = true

    /// The JS message recoder
    fileprivate var decoder: HCaptchaDecoder!

    /// Indicates if the script has already been loaded by the `webView`
    fileprivate var didFinishLoading = false {
        didSet {
            if didFinishLoading {
                onDidFinishLoading?()
            }
        }
    }

    /// The observer for `.UIWindowDidBecomeVisible`
    fileprivate var observer: NSObjectProtocol?

    /// Base URL for WebView
    fileprivate var baseURL: URL!

    /// Actual HTML
    fileprivate var formattedHTML: String!

    /// Keep error If it happens before validate call
    fileprivate var lastError: HCaptchaError?

    /// The webview that executes JS code
    lazy var webView: WKWebView = {
        let webview = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 1, height: 1),
            configuration: self.buildConfiguration()
        )
        webview.accessibilityIdentifier = "webview"
        webview.accessibilityTraits = UIAccessibilityTraits.link
        webview.isHidden = true

        return webview
    }()

    /**
     - parameters:
         - html: The HTML string to be loaded onto the webview
         - apiKey: The hCaptcha sitekey
         - baseURL: The URL configured with the sitekey
         - endpoint: The JS API endpoint to be loaded onto the HTML file.
         - size: Size of visible area
         - rqdata: Custom supplied challenge data
         - theme: Widget theme, value must be valid JS Object or String with brackets
     */
    init(html: String, apiKey: String, baseURL: URL, endpoint: URL,
         size: HCaptchaSize, rqdata: String?, theme: String) {
        super.init()
        self.baseURL = baseURL
        self.decoder = HCaptchaDecoder { [weak self] result in
            self?.handle(result: result)
        }
        self.formattedHTML = String(format: html, arguments: ["apiKey": apiKey,
                                                              "endpoint": endpoint.absoluteString,
                                                              "size": size.rawValue,
                                                              "rqdata": rqdata ?? "",
                                                              "theme": theme,
                                                              "debugInfo": "[]"])

        setupWebview(html: self.formattedHTML, url: baseURL)
    }

    /**
     - parameter view: The view that should present the webview.

     Starts the challenge validation
     */
    func validate(on view: UIView) {
#if DEBUG
        guard !shouldSkipForTests else {
            completion?(HCaptchaResult(token: ""))
            return
        }
#endif
        view.addSubview(webView)
        if webView.bounds.size == CGSize.zero {
            self.configureWebView?(self.webView)
        }

        executeJS(command: .execute)
    }


    /// Stops the execution of the webview
    func stop() {
        webView.stopLoading()
    }

    /**
     Resets the HCaptcha.

     The reset is achieved by calling `ghcaptcha.reset()` on the JS API.
     */
    func reset() {
        configureWebViewDispatchToken = UUID()
        if didFinishLoading {
            executeJS(command: .reset)
            didFinishLoading = false
        } else {
            setupWebview(html: formattedHTML, url: baseURL)
        }
    }
}

// MARK: - Private Methods

/** Private methods for HCaptchaWebViewManager
 */
fileprivate extension HCaptchaWebViewManager {
    /**
     - returns: An instance of `WKWebViewConfiguration`

     Creates a `WKWebViewConfiguration` to be added to the `WKWebView` instance.
     */
    func buildConfiguration() -> WKWebViewConfiguration {
        let controller = WKUserContentController()
        controller.add(decoder, name: "hcaptcha")

        let conf = WKWebViewConfiguration()
        conf.userContentController = controller

        return conf
    }

    /**
     - parameter result: A `HCaptchaDecoder.Result` with the decoded message.

     Handles the decoder results received from the webview
     */
    func handle(result: HCaptchaDecoder.Result) {
        switch result {
        case .token(let token):
            completion?(HCaptchaResult(token: token))

        case .error(let error):
            handle(error: error)
            onEvent?(.error, error)

        case .showHCaptcha:
            webView.isHidden = false

        case .didLoad:
            didLoad()

        case .onOpen:
            onEvent?(.open, nil)

        case .onExpired:
            onEvent?(.expired, nil)

        case .onChallengeExpired:
            onEvent?(.challengeExpired, nil)

        case .onClose:
            onEvent?(.close, nil)

        case .log(let message):
            #if DEBUG
                print("[JS LOG]:", message)
            #endif
        }
    }

    private func handle(error: HCaptchaError) {
        switch error {
        case HCaptchaError.challengeClosed:
            completion?(HCaptchaResult(error: error))
        case HCaptchaError.networkError:
            if let completion = completion {
                completion(HCaptchaResult(error: error))
            } else {
                lastError = error
            }
        default:
            if shouldResetOnError, let view = webView.superview {
                reset()
                validate(on: view)
            } else {
                completion?(HCaptchaResult(error: error))
            }
        }
    }

    private func didLoad() {
        didFinishLoading = true
        if completion != nil {
            executeJS(command: .execute)
        }
        if configureWebView != nil {
            DispatchQueue.once(token: configureWebViewDispatchToken) { [weak self] in
                guard let `self` = self else { return }
                self.configureWebView?(self.webView)
            }
        }
    }

    /**
     - parameters:
         - html: The embedded HTML file
         - url: The base URL given to the webview

     Adds the webview to a valid UIView and loads the initial HTML file
     */
    func setupWebview(html: String, url: URL) {
        if let window = UIApplication.shared.keyWindow {
            setupWebview(on: window, html: formattedHTML, url: baseURL)
        } else {
            observer = NotificationCenter.default.addObserver(
                forName: UIWindow.didBecomeVisibleNotification,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                guard let window = notification.object as? UIWindow else { return }
                guard let slf = self else { return }
                slf.setupWebview(on: window, html: slf.formattedHTML, url: slf.baseURL)
            }
        }
    }

    /**
     - parameters:
         - window: The window in which to add the webview
         - html: The embedded HTML file
         - url: The base URL given to the webview

     Adds the webview to a valid UIView and loads the initial HTML file
     */
    func setupWebview(on window: UIWindow, html: String, url: URL) {
        window.addSubview(webView)
        webView.loadHTMLString(html, baseURL: url)
        webView.navigationDelegate = self

        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /**
     - parameters:
         - command: The JavaScript command to be executed

     Executes the JS command that loads the HCaptcha challenge. This method has no effect if the webview hasn't
     finished loading.
     */
    func executeJS(command: JSCommand) {
        guard didFinishLoading else {
            if let error = lastError {
                DispatchQueue.main.async { [weak self] in
                    self?.completion?(HCaptchaResult(error: error))
                    self?.lastError = nil
                }
                if error == .networkError {
                    self.webView.loadHTMLString(formattedHTML, baseURL: baseURL)
                }
            }
            return
        }

        webView.evaluateJavaScript(command.rawValue) { [weak self] _, error in
            if let error = error {
                self?.decoder.send(error: .unexpected(error))
            }
        }
    }
}

extension HCaptchaWebViewManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            if UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }
}
