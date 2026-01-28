//
//  HCaptchaWebViewManager.swift
//  HCaptcha

import Foundation
import WebKit


/** Handles comunications with the webview containing the HCaptcha challenge.
 */
internal class HCaptchaWebViewManager: NSObject {
    typealias Log = HCaptchaLogger

    fileprivate struct Constants {
        static let BotUserAgent = "bot/2.1"
    }

    fileprivate let webViewInitSize = CGSize(width: 1, height: 1)

    /// True if validation  token was dematerialized
    var resultHandled: Bool = false

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

    /// Verification parameters (e.g., phone prefix/number for MFA flows)
    var verifyParams: HCaptchaVerifyParams?

    /// The JS message recoder
    var decoder: HCaptchaDecoder!

    /// Indicates if the script has already been loaded by the `webView`
    var didFinishLoading = false {
        didSet {
            if didFinishLoading {
                onDidFinishLoading?()
            }
        }
    }

    var loadingTimer: Timer?

    /// The observer for `.UIWindowDidBecomeVisible`
    var observer: NSObjectProtocol?

    /// Base URL for WebView
    var baseURL: URL!

    /// Actual HTML
    var formattedHTML: String!

    /// Passive apiKey
    var passiveApiKey: Bool

    /// Keep error If it happens before validate call
    var lastError: HCaptchaError?

    /// Timeout to throw `.htmlLoadError` if no `didLoad` called
    let loadingTimeout: TimeInterval

    /// Responsible for external link handling
    let urlOpener: HCaptchaURLOpener

    /// Stop async webView configuration
    private var stopInitWebViewConfiguration = false

    /// The webview that executes JS code
    lazy var webView: WKWebView = {
        let debug = Log.minLevel == .debug
        let webview = WKWebView(
            frame: CGRect(origin: CGPoint.zero, size: webViewInitSize),
            configuration: self.buildConfiguration()
        )
        webview.accessibilityIdentifier = "webview"
        webview.accessibilityTraits = UIAccessibilityTraits.link
        webview.isHidden = true
        if debug {
            if #available(iOS 16.4, *) {
                webview.perform(Selector(("setInspectable:")), with: true)
            }
            webview.evaluateJavaScript("navigator.userAgent") { (result, _) in
                Log.debug("WebViewManager WKWebView UserAgent: \(result ?? "nil")")
            }
        }
        Log.debug("WebViewManager WKWebView instance created")

        return webview
    }()

    /**
     - parameters:
         - `config`: HCaptcha config
         - `urlOpener`:  class
     */
    init(config: HCaptchaConfig, urlOpener: HCaptchaURLOpener = HCapchaAppURLOpener()) {
        Log.debug("WebViewManager.init")
        self.urlOpener = urlOpener
        self.baseURL = config.baseURL
        self.passiveApiKey = config.passiveApiKey
        self.loadingTimeout = config.loadingTimeout
        super.init()
        self.decoder = HCaptchaDecoder { [weak self] result in
            self?.handle(result: result)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let arguments = ["apiKey": config.apiKey,
                             "endpoint": config.actualEndpoint.absoluteString,
                             "size": config.size.rawValue,
                             "orientation": config.orientation.rawValue,
                             "rqdata": config.rqdata ?? "",
                             "theme": config.actualTheme,
                             "debugInfo": HCaptchaDebugInfo.json]
            self.formattedHTML = String(format: config.html, arguments: arguments)
            Log.debug("WebViewManager.init formattedHTML built")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard !self.stopInitWebViewConfiguration else { return }

                self.setupWebview(html: self.formattedHTML, url: self.baseURL)
            }
        }
    }

    /**
     - parameter view: The view that should present the webview.

     Starts the challenge validation
     */
    func validate(on view: UIView?) {
        Log.debug("WebViewManager.validate on: \(String(describing: view))")
        resultHandled = false

        if !passiveApiKey {
            guard let view = view else {
                completion?(HCaptchaResult(self, error: .failedSetup))
                return
            }

            view.addSubview(webView)
            if self.didFinishLoading && (webView.bounds.size == CGSize.zero || webView.bounds.size == webViewInitSize) {
                self.doConfigureWebView()
            }
        }

        executeJS(command: .execute(verifyParams))
    }

    /// Stops the execution of the webview
    func stop() {
        Log.debug("WebViewManager.stop")
        stopInitWebViewConfiguration = true
        webView.stopLoading()
        resultHandled = true
        loadingTimer?.invalidate()
        loadingTimer = nil
    }

    /**
     Resets the HCaptcha.

     The reset is achieved by calling `ghcaptcha.reset()` on the JS API.
     */
    func reset() {
        Log.debug("WebViewManager.reset")
        configureWebViewDispatchToken = UUID()
        stopInitWebViewConfiguration = false
        resultHandled = false
        if didFinishLoading {
            executeJS(command: .reset)
            didFinishLoading = false
        } else if let formattedHTML = self.formattedHTML {
            setupWebview(html: formattedHTML, url: baseURL)
        }
    }
}
