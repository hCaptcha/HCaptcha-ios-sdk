//
//  HCaptchaDecoder.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation
import WebKit


/** The Decoder of javascript messages from the webview
 */
internal class HCaptchaDecoder: NSObject {
    /** The decoder result.
     */
    enum Result {
        /// A result token, if any
        case token(String)

        /// Indicates that the webview containing the challenge should be displayed.
        case showHCaptcha

        /// Any errors
        case error(HCaptchaError)

        /// Did finish loading resources
        case didLoad

        /// Logs a string onto the console
        case log(String)
    }

    /// The closure that receives messages
    fileprivate let sendMessage: ((Result) -> Void)

    /**
     - parameter didReceiveMessage: A closure that receives a HCaptchaDecoder.Result

     Initializes a decoder with a completion closure.
     */
    init(didReceiveMessage: @escaping (Result) -> Void) {
        sendMessage = didReceiveMessage

        super.init()
    }


    /**
     - parameter error: The error to be sent.

     Sends an error to the completion closure
     */
    func send(error: HCaptchaError) {
        sendMessage(.error(error))
    }
}


// MARK: Script Handler

/** Makes HCaptchaDecoder conform to `WKScriptMessageHandler`
 */
extension HCaptchaDecoder: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else {
            return sendMessage(.error(.wrongMessageFormat))
        }

        sendMessage(Result.from(response: dict))
    }
}


// MARK: - Result

/** Private methods on `HCaptchaDecoder.Result`
 */
fileprivate extension HCaptchaDecoder.Result {

    /**
     - parameter response: A dictionary containing the message to be parsed
     - returns: A decoded HCaptchaDecoder.Result

     Parses a dict received from the webview onto a `HCaptchaDecoder.Result`
     */
    static func from(response: [String: Any]) -> HCaptchaDecoder.Result {
        if let token = response["token"] as? String {
            return .token(token)
        }
        else if let message = response["log"] as? String {
            return .log(message)
        }
        else if let error = response["error"] as? Int {
            return from(error)
        }

        if let action = response["action"] as? String {
            switch action {
            case "showHCaptcha":
                return .showHCaptcha

            case "didLoad":
                return .didLoad

            default:
                break
            }
        }

        if let message = response["log"] as? String {
            return .log(message)
        }

        return .error(.wrongMessageFormat)
    }

    private static func from(_ error: Int) -> HCaptchaDecoder.Result {
        switch error {
        case 1:
            return .error(.htmlLoadError)

        case 29:
            return .error(.failedSetup)

        case 15:
            return .error(.responseExpired)

        case 31:
            return .error(.failedRender)

        case 30:
            return .error(.userClosed)

        default:
            return .error(.wrongMessageFormat)
        }
    }
}
