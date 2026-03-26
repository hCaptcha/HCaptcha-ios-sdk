//
//  HCaptchaWebViewManager+Private.swift
//  HCaptcha
//
//  Copyright © 2025 HCaptcha. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/** Private methods for HCaptchaWebViewManager
 */
extension HCaptchaWebViewManager {
    /**
     - returns: An instance of `WKWebViewConfiguration`

     Creates a `WKWebViewConfiguration` to be added to the `WKWebView` instance.
     */
    func buildConfiguration() -> WKWebViewConfiguration {
        let controller = WKUserContentController()
        controller.add(decoder, name: "hcaptcha")

        let conf = WKWebViewConfiguration()
        conf.userContentController = controller
        conf.allowsInlineMediaPlayback = true
        conf.mediaTypesRequiringUserActionForPlayback = []

        return conf
    }

    func startLoadingTimer() {
        cancelLoadingTimer()
        loadingTimer = Timer.scheduledTimer(withTimeInterval: self.loadingTimeout, repeats: false) { [weak self] _ in
            self?.handle(error: .htmlLoadError)
        }
    }

    func cancelLoadingTimer() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }

    /**
     - parameter result: A `HCaptchaDecoder.Result` with the decoded message.

     Handles the decoder results received from the webview
     */
    func handle(result: HCaptchaDecoder.Result) {
        Log.debug("WebViewManager.handleResult: \(result)")

        switch result {
        case .token(let token): handleToken(token)
        case .error(let error): handleDecoderError(error)
        case .showHCaptcha: webView.isHidden = false
        case .didLoad: onDidLoad()
        case .onOpen: onEvent?(.open, nil)
        case .onExpired: onEvent?(.expired, nil)
        case .onChallengeExpired: onEvent?(.challengeExpired, nil)
        case .onClose: onEvent?(.close, nil)
        case .log(_): break
        }
    }

    private func handleToken(_ token: String) {
        guard !resultHandled else {
            Log.debug("WebViewManager.handleResult skip token as handled")
            return
        }
        complete(HCaptchaResult(self, token: token))
    }

    private func handleDecoderError(_ error: HCaptchaError) {
        guard !resultHandled else {
            Log.debug("WebViewManager.handleResult skip error as handled")
            return
        }
        handle(error: error)
        onEvent?(.error, error)
    }

    private func onDidLoad() {
        Log.debug("WebViewManager.onDidLoad")
        loadingState = .loaded
        cancelLoadingTimer()
        if completion != nil {
            executeJS(command: .execute(verifyParams))
        }
        self.doConfigureWebView()
    }

    /**
     Call client's clousure to configure WebVIew
     */
    func doConfigureWebView() {
        Log.debug("WebViewManager.doConfigureWebView")
        if configureWebView != nil && !passiveApiKey {
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
            setupWebview(on: window, html: html, url: url)
        } else {
            observer = NotificationCenter.default.addObserver(
                forName: UIWindow.didBecomeVisibleNotification,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                guard let window = notification.object as? UIWindow else { return }
                guard let slf = self else { return }
                slf.setupWebview(on: window, html: html, url: url)
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
        Log.debug("WebViewManager.setupWebview")
        loadingState = .loading
        if webView.superview == nil {
            window.addSubview(webView)
        }
        webView.loadHTMLString(html, baseURL: url)
        if webView.navigationDelegate == nil {
            webView.navigationDelegate = self
            webView.uiDelegate = self
        }
        startLoadingTimer()

        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /**
     - parameter command: The JavaScript command to be executed

     Executes the JS command that loads the HCaptcha challenge. This method has no effect if the webview hasn't
     finished loading.
     */
    func executeJS(command: JSCommand) {
        Log.debug("WebViewManager.executeJS: \(command)")
        if loadingState.isLoaded {
            webView.evaluateJavaScript(command.rawValue) { [weak self] _, error in
                if let error = error {
                    self?.decoder.send(error: .unexpected(error))
                }
            }
        } else if let error = loadingState.error {
            cancelLoadingTimer()
            if error == .networkError {
                Log.debug("WebViewManager reloads html after networkError")
                loadingState = .loading
                webView.loadHTMLString(formattedHTML, baseURL: baseURL)
                startLoadingTimer()
            } else {
                complete(HCaptchaResult(self, error: error))
            }
        }
    }

    func complete(_ result: HCaptchaResult) {
        let completion = self.completion
        self.completion = nil
        completion?(result)
    }
}
