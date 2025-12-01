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

        return conf
    }

    /**
     - parameter result: A `HCaptchaDecoder.Result` with the decoded message.

     Handles the decoder results received from the webview
     */
    func handle(result: HCaptchaDecoder.Result) {
        Log.debug("WebViewManager.handleResult: \(result)")

        guard !resultHandled else {
            Log.debug("WebViewManager.handleResult skip as handled")
            return
        }

        switch result {
        case .token(let token):
            completion?(HCaptchaResult(self, token: token))
        case .error(let error):
            handle(error: error)
            onEvent?(.error, error)
        case .showHCaptcha: webView.isHidden = false
        case .didLoad: didLoad()
        case .onOpen: onEvent?(.open, nil)
        case .onExpired: onEvent?(.expired, nil)
        case .onChallengeExpired: onEvent?(.challengeExpired, nil)
        case .onClose: onEvent?(.close, nil)
        case .log(_): break
        }
    }

    private func handle(error: HCaptchaError) {
        loadingTimer?.invalidate()
        loadingTimer = nil
        if error == .sessionTimeout {
            if verifyParams?.resetOnError == true, let view = webView.superview {
                reset()
                validate(on: view)
            } else {
                completion?(HCaptchaResult(self, error: error))
            }
        } else {
            if let completion = completion {
                completion(HCaptchaResult(self, error: error))
            } else {
                lastError = error
            }
        }
    }

    private func didLoad() {
        Log.debug("WebViewManager.didLoad")
        if completion != nil {
            executeJS(command: .execute(), didLoad: true)
        }
        didFinishLoading = true
        loadingTimer?.invalidate()
        loadingTimer = nil
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
        if webView.superview == nil {
            window.addSubview(webView)
        }
        webView.loadHTMLString(html, baseURL: url)
        if webView.navigationDelegate == nil {
            webView.navigationDelegate = self
            webView.uiDelegate = self
        }
        loadingTimer?.invalidate()
        loadingTimer = Timer.scheduledTimer(withTimeInterval: self.loadingTimeout, repeats: false, block: { _ in
            self.handle(error: .htmlLoadError)
            self.loadingTimer = nil
        })

        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /**
     - parameters:
         - command: The JavaScript command to be executed
         - didLoad: True if didLoad event already occured
         - journeyEvents: JSON string of journey events to pass to JavaScript

     Executes the JS command that loads the HCaptcha challenge. This method has no effect if the webview hasn't
     finished loading.
     */
    func executeJS(command: JSCommand, didLoad: Bool = false) {
        Log.debug("WebViewManager.executeJS: \(command)")
        guard didLoad else {
            if let error = lastError {
                loadingTimer?.invalidate()
                loadingTimer = nil
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    Log.debug("WebViewManager complete with pendingError: \(error)")

                    self.completion?(HCaptchaResult(self, error: error))
                    self.lastError = nil
                }
                if error == .networkError {
                    Log.debug("WebViewManager reloads html after \(error) error")
                    self.webView.loadHTMLString(formattedHTML, baseURL: baseURL)
                }
            }
            return
        }

        // Execute the JavaScript command
        let jsCommand = command.rawValue

        webView.evaluateJavaScript(jsCommand) { [weak self] _, error in
            if let error = error {
                self?.decoder.send(error: .unexpected(error))
            }
        }
    }

    func executeJS(command: JSCommand) {
        executeJS(command: command, didLoad: self.didFinishLoading)
    }
}
