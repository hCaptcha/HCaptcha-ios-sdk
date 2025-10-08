//
//  HCaptchaWebViewManager__Tests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 13/04/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@testable import HCaptcha

import WebKit
import XCTest


class HCaptchaWebViewManager__Tests: XCTestCase {

    fileprivate var apiKey: String!
    fileprivate var presenterView: UIView!

    override func setUp() {
        super.setUp()

        presenterView = UIApplication.shared.keyWindow?.rootViewController?.view
        apiKey = String(arc4random())
    }

    override func tearDown() {
        presenterView = nil
        apiKey = nil

        super.tearDown()
    }

    // MARK: Validate

    func test__Validate__Token() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "load token")
        var result1: HCaptchaResult?

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey)
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { response in
            result1 = response
            exp1.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)


        // Verify
        XCTAssertNotNil(result1)
        XCTAssertNil(result1?.error)
        XCTAssertEqual(result1?.token, apiKey)


        // Validate again
        let exp2 = expectation(description: "reload token")
        var result2: HCaptchaResult?

        // Validate
        manager.validate(on: presenterView) { response in
            result2 = response
            exp2.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)


        // Verify
        XCTAssertNotNil(result2)
        XCTAssertNil(result2?.error)
        XCTAssertEqual(result2?.token, apiKey)
    }


    func test__Validate__Show_HCaptcha() {
        let exp = expectation(description: "show hcaptcha")

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        manager.configureWebView { _ in
            exp.fulfill()
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        waitForExpectations(timeout: TestTimeouts.standard)
    }


    func test__Validate__Message_Error() {
        let exp0 = expectation(description: "should call configureWebView")
        var result: HCaptchaResult?
        let exp1 = expectation(description: "message error")

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "\"foobar\"")
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        manager.validate(on: presenterView, resetOnError: false) { response in
            result = response
            exp1.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)

        // Verify
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.error, .wrongMessageFormat)
        XCTAssertNil(result?.token)
    }

    func test__Validate__JS_Error() {
        var result: HCaptchaResult?
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "js error")

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "foobar")
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        manager.validate(on: presenterView, resetOnError: false) { response in
            result = response
            exp1.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)

        // Verify
        XCTAssertNotNil(result)
        XCTAssertNotNil(result?.error)
        XCTAssertNil(result?.token)

        switch result?.error {
        case .unexpected(let error as NSError):
            XCTAssertEqual(error.code, WKError.javaScriptExceptionOccurred.rawValue)
        default:
            XCTFail("Unexpected error received")
        }
    }

    // MARK: Configure WebView

    func test__Configure_Web_View__Empty() {
        let exp = expectation(description: "configure webview")

        // Configure WebView
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            exp.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    func test__Configure_Web_View() {
        let exp = expectation(description: "configure webview")

        // Configure WebView
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        manager.configureWebView { [unowned self] webView in
            XCTAssertEqual(webView.superview, self.presenterView)
            exp.fulfill()
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    func test__Configure_Web_View__Called_Once() {
        var count = 0
        let exp0 = expectation(description: "configure webview")

        // Configure WebView
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        manager.configureWebView { _ in
            if count < 3 {
                manager.webView.evaluateJavaScript("execute();") { XCTAssertNil($1) }
            }

            count += 1
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        waitForExpectations(timeout: TestTimeouts.standard)

        let exp1 = expectation(description: "waiting for extra calls")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: exp1.fulfill)
        waitForExpectations(timeout: TestTimeouts.standard)

        XCTAssertEqual(count, 1)
    }

    func test__Configure_Web_View__Called_Again_With_Reset() {
        let exp0 = expectation(description: "configure webview 0")

        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        // Configure Webview
        manager.configureWebView { _ in
            manager.webView.evaluateJavaScript("execute();") { XCTAssertNil($1) }
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        waitForExpectations(timeout: TestTimeouts.standard)

        // Reset and ensure it calls again
        let exp1 = expectation(description: "configure webview 1")

        manager.configureWebView { _ in
            manager.webView.evaluateJavaScript("execute();") { XCTAssertNil($1) }
            exp1.fulfill()
        }

        manager.reset()
        waitForExpectations(timeout: TestTimeouts.standard)
    }

    func test__Configure_Web_View__Handle_rqdata_Without_JS_Error() {
        let exp0 = expectation(description: "configure webview")
        let exp1 = expectation(description: "execute JS complete")

        // Configure WebView
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}",
                                             rqdata: "some rqdata")
        manager.configureWebView { _ in
            manager.webView.evaluateJavaScript("execute();") {
                XCTAssertNil($1)
                exp1.fulfill()
            }
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    // MARK: Stop

    func test__Stop() {
        let exp = expectation(description: "stop loading")

        // Stop
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        manager.stop()
        manager.configureWebView { _ in
            XCTFail("should not ask to configure the webview")
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not validate")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            exp.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    func test__Reset_After_Stop() {
        let exp0 = expectation(description: "stop loading")
        let exp1 = expectation(description: "configureWebView called")
        let exp2 = expectation(description: "token recieved")

        // Stop
        let manager = HCaptchaWebViewManager(messageBody: "{token: \"some_token\"}")
        manager.stop()
        manager.configureWebView { _ in
            XCTFail("should not ask to configure the webview")
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not validate")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            exp0.fulfill()
        }

        manager.reset()

        manager.configureWebView { _ in
            exp1.fulfill()
        }

        manager.validate(on: presenterView) { result in
            let token = try? result.dematerialize()
            XCTAssertEqual("some_token", token)
            exp2.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    // MARK: Setup

    func test__Key_Setup() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "setup key")
        var result: HCaptchaResult?

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey)
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { response in
            result = response
            exp1.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)

        XCTAssertNotNil(result)
        XCTAssertNil(result?.error)
        XCTAssertEqual(result?.token, apiKey)
    }

    func test__Endpoint_Setup() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "setup endpoint")
        let endpoint = URL(string: "https://some.endpoint")!
        var result: HCaptchaResult?

        let manager = HCaptchaWebViewManager(messageBody: "{token: endpoint}", endpoint: endpoint)
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { response in
            result = response
            exp1.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)

        XCTAssertNotNil(result)
        XCTAssertNil(result!.error)
        XCTAssertTrue(result!.token!.contains("endpoint=https%3A%2F%2Fsome.endpoint"))
    }

    // MARK: Reset

    func test__Reset() {
        let exp0 = expectation(description: "should call configureWebView #1")
        let exp1 = expectation(description: "fail on first execution")
        var result1: HCaptchaResult?

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey, shouldFail: true)
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        // Error
        manager.validate(on: presenterView, resetOnError: false) { result in
            result1 = result
            exp1.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)

        let exp2 = expectation(description: "should call configureWebView #2")
        manager.configureWebView { _ in
            exp2.fulfill()
        }

        XCTAssertEqual(result1?.error, .sessionTimeout)

        // Resets and tries again
        let exp3 = expectation(description: "validates after reset")
        var result3: HCaptchaResult?

        manager.reset()
        manager.validate(on: presenterView, resetOnError: false) { result in
            result3 = result
            exp3.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)

        XCTAssertNil(result3?.error)
        XCTAssertEqual(result3?.token, apiKey)
    }

    func test__Validate__Reset_On_Error() {
        let exp0 = expectation(description: "should call configureWebView")
        var exp0Count = 0
        let exp1 = expectation(description: "should call onEvent")
        let exp2 = expectation(description: "fail on first execution")
        let exp3 = expectation(description: "hcaptcha opened")
        var result: HCaptchaResult?

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey, shouldFail: true)
        manager.configureWebView { _ in
            exp0Count += 1
            if exp0Count == 2 {
                exp0.fulfill()
            }
        }

        manager.onEvent = { (event, error) in
            XCTAssertTrue([.error, .open].contains(event))
            switch event {
            case .error:
                XCTAssertEqual(.error, event)
                XCTAssertEqual(HCaptchaError.sessionTimeout, error as? HCaptchaError)
                exp1.fulfill()
            case .open:
                exp3.fulfill()
            default:
                XCTFail("Unexpected event \(event)")
            }
        }

        // Error
        manager.validate(on: presenterView, resetOnError: true) { response in
            result = response

            exp2.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)

        XCTAssertNil(result?.error)
        XCTAssertEqual(result?.token, apiKey)
    }

    // MARK: On Did Finish Loading

    func test__Did_Finish_Loading__Immediate() {
        let exp = expectation(description: "did finish loading")

        let manager = HCaptchaWebViewManager()

        // // Should call closure immediately since it's already loaded
        manager.onDidFinishLoading = {
            manager.onDidFinishLoading = exp.fulfill
        }

        waitForExpectations(timeout: TestTimeouts.short)
    }

    func test__Did_Finish_Loading__Delayed() {
        let exp = expectation(description: "did finish loading")

        let manager = HCaptchaWebViewManager(shouldFail: true)

        var called = false
        manager.onDidFinishLoading = {
            called = true
        }

        XCTAssertFalse(called)

        // Reset
        manager.onDidFinishLoading = exp.fulfill
        manager.reset()

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    func test__OnEvent_Open_Callback() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "setup key")
        let exp2 = expectation(description: "hcaptcha opened")
        var result: HCaptchaResult?

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey)
        manager.configureWebView { _ in
            exp0.fulfill()
        }
        manager.onEvent = { (event, data) in
            XCTAssertNil(data)
            XCTAssertEqual(event, .open)
            exp1.fulfill()
        }

        manager.validate(on: presenterView) { response in
            result = response
            exp2.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)

        XCTAssertNotNil(result)
        XCTAssertNil(result?.error)
        XCTAssertEqual(result?.token, apiKey)
    }

    func test__OnEvent_Without_Validation() {
        let testParams: [(String, HCaptchaEvent)] = [("onChallengeExpired", .challengeExpired),
                                                     ("onExpired", .expired),
                                                     ("onClose", .close)]

        testParams.forEach { (action, expectedEventType) in
            let exp0 = expectation(description: "should call configureWebView")
            let exp = expectation(description: "challenge expired received")

            let manager = HCaptchaWebViewManager(messageBody: "{action: \"\(action)\"}")
            manager.configureWebView { _ in
                exp0.fulfill()
            }
            manager.onEvent = { (event, data) in
                XCTAssertNil(data)
                XCTAssertEqual(expectedEventType, event)
                exp.fulfill()
            }

            manager.validate(on: presenterView) { _ in
                XCTFail("should not validate")
            }

            waitForExpectations(timeout: TestTimeouts.standard)
        }
    }

    func test__Open_External_Link() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "_target link should be checked")
        let exp2 = expectation(description: "_target link should be opened")

        let manager = HCaptchaWebViewManager(messageBody: "{action: \"openExternalPage\"}",
                                             apiKey: apiKey,
                                             urlOpener: TestURLOpener(exp1, exp2))
        manager.configureWebView { _ in
            exp0.fulfill()
        }
        wait(for: [exp0], timeout: TestTimeouts.short)
        manager.validate(on: presenterView)

        wait(for: [exp1, exp2], timeout: TestTimeouts.standard)
    }

    func test__Invalid_HTML() {
        let exp = expectation(description: "bad theme value")

        let manager = HCaptchaWebViewManager(messageBody: "{ invalid json",
                                             apiKey: apiKey)
        manager.shouldResetOnError = false
        manager.configureWebView { _ in
            XCTFail("should not ask to configure the webview")
        }

        manager.validate(on: presenterView, resetOnError: false) { response in
            XCTAssertEqual(HCaptchaError.htmlLoadError, response.error)
            exp.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    func test__HTML_Load_Error_Timeout() {
        let exp = expectation(description: "didLoad never called")

        let manager = HCaptchaWebViewManager(html: "<html>", apiKey: apiKey, loadingTimeout: 0.5)
        manager.shouldResetOnError = false
        manager.configureWebView { _ in
            XCTFail("should not ask to configure the webview")
        }

        manager.validate(on: presenterView, resetOnError: false) { response in
            XCTAssertEqual(HCaptchaError.htmlLoadError, response.error)
            exp.fulfill()
        }

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    func test__Validate_Passive_Key_On_Nil_View() {
        let exp = expectation(description: "wait for completion")

        let manager = HCaptchaWebViewManager(messageBody: "{token: \"success-token\"}", passiveApiKey: true)
        manager.shouldResetOnError = false
        manager.completion = { response in
            XCTAssertEqual(try? response.dematerialize(), "success-token")
            exp.fulfill()
        }
        manager.validate(on: nil)

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    func test__Validate_Non_Passive_Key_On_Nil_View() {
        let exp = expectation(description: "didLoad never called")

        let manager = HCaptchaWebViewManager(messageBody: "{token: \"should-not-be-delivered\"}", passiveApiKey: false)
        manager.shouldResetOnError = false

        manager.completion = { response in
            XCTAssertEqual(HCaptchaError.failedSetup, response.error)
            exp.fulfill()
        }

        manager.validate(on: nil)

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    func test__Sms_open() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "sms link should be checked")
        let exp2 = expectation(description: "sms link should be opened")

        let manager = HCaptchaWebViewManager(messageBody: "{action: \"sms\"}",
                                             apiKey: apiKey,
                                             urlOpener: TestURLOpener(exp1, exp2))
        manager.configureWebView { _ in
            exp0.fulfill()
        }
        wait(for: [exp0], timeout: TestTimeouts.standard)
        manager.validate(on: presenterView)

        wait(for: [exp1, exp2], timeout: TestTimeouts.standard)
    }

    // MARK: - Verify Params Tests

    func test__JSCommand_execute__withVerifyParams() {
        // Given
        let phonePrefix = "44"
        let phoneNumber = "1234567890"
        let verifyParams = HCaptchaVerifyParams(phonePrefix: phonePrefix, phoneNumber: phoneNumber, resetOnError: false)
        let command = HCaptchaWebViewManager.JSCommand.execute(verifyParams)

        // When
        let rawValue = command.rawValue

        // Then
        XCTAssertTrue(rawValue.contains("execute("))
        XCTAssertTrue(rawValue.contains("\"phonePrefix\":\"44\""))
        XCTAssertTrue(rawValue.contains("\"phoneNumber\":\"1234567890\""))
        XCTAssertTrue(rawValue.contains("\"resetOnError\":false"))
        XCTAssertTrue(rawValue.hasSuffix(");"))
    }

    func test__JSCommand_execute__withNilVerifyParams() {
        // Given
        let command = HCaptchaWebViewManager.JSCommand.execute(nil)

        // When
        let rawValue = command.rawValue

        // Then
        XCTAssertEqual(rawValue, "execute();")
    }

    func test__JSCommand_execute__withPhonePrefixOnly() {
        // Given
        let phonePrefix = "44"
        let verifyParams = HCaptchaVerifyParams(phonePrefix: phonePrefix)
        let command = HCaptchaWebViewManager.JSCommand.execute(verifyParams)

        // When
        let rawValue = command.rawValue

        // Then
        XCTAssertTrue(rawValue.contains("execute("))
        XCTAssertTrue(rawValue.contains("\"phonePrefix\":\"44\""))
        XCTAssertTrue(rawValue.contains("\"resetOnError\":true"))
        XCTAssertFalse(rawValue.contains("phoneNumber"))
        XCTAssertTrue(rawValue.hasSuffix(");"))
    }

    func test__JSCommand_execute__withPhoneNumberOnly() {
        // Given
        let phoneNumber = "+1234567890"
        let verifyParams = HCaptchaVerifyParams(phoneNumber: phoneNumber)
        let command = HCaptchaWebViewManager.JSCommand.execute(verifyParams)

        // When
        let rawValue = command.rawValue

        // Then
        XCTAssertTrue(rawValue.contains("execute("))
        XCTAssertTrue(rawValue.contains("\"phoneNumber\":\"+1234567890\""))
        XCTAssertTrue(rawValue.contains("\"resetOnError\":true"))
        XCTAssertFalse(rawValue.contains("phonePrefix"))
        XCTAssertTrue(rawValue.hasSuffix(");"))
    }

    func test__validate__withVerifyParams__setsVerifyParams() {
        // Given
        let exp = expectation(description: "verify params are set correctly")
        let phonePrefix = "44"
        let phoneNumber = "1234567890"
        let resetOnError = false
        let verifyParams = HCaptchaVerifyParams(phonePrefix: phonePrefix,
                                         phoneNumber: phoneNumber,
                                         resetOnError: resetOnError)
        let manager = HCaptchaWebViewManager(messageBody: "{token: \"test_token\"}")

        // When
        manager.verifyParams = verifyParams
        manager.shouldResetOnError = resetOnError

        // Then
        XCTAssertEqual(manager.verifyParams?.phonePrefix, phonePrefix)
        XCTAssertEqual(manager.verifyParams?.phoneNumber, phoneNumber)
        XCTAssertEqual(manager.verifyParams?.resetOnError, resetOnError)
        XCTAssertEqual(manager.shouldResetOnError, resetOnError)
        exp.fulfill()

        waitForExpectations(timeout: TestTimeouts.standard)
    }

    func test__validate__withVerifyParams__setsManagerProperties() {
        // Given
        let phonePrefix = "44"
        let resetOnError = false
        let verifyParams = HCaptchaVerifyParams(phonePrefix: phonePrefix,
                                         resetOnError: resetOnError)
        let manager = HCaptchaWebViewManager(messageBody: "{token: \"test_token\"}")

        // When
        manager.verifyParams = verifyParams
        manager.shouldResetOnError = resetOnError

        // Then
        XCTAssertEqual(manager.verifyParams?.phonePrefix, phonePrefix)
        XCTAssertEqual(manager.verifyParams?.resetOnError, resetOnError)
        XCTAssertEqual(manager.shouldResetOnError, resetOnError)
    }

    func test__JSCommand_execute__withEmptyVerifyParams() {
        // Given
        let verifyParams = HCaptchaVerifyParams() // Empty params
        let command = HCaptchaWebViewManager.JSCommand.execute(verifyParams)

        // When
        let rawValue = command.rawValue

        // Then
        XCTAssertTrue(rawValue.contains("execute("))
        XCTAssertTrue(rawValue.contains("\"resetOnError\":true"))
        XCTAssertFalse(rawValue.contains("phonePrefix"))
        XCTAssertFalse(rawValue.contains("phoneNumber"))
        XCTAssertTrue(rawValue.hasSuffix(");"))
    }

    func test__JSCommand_execute__withBothPhoneValues() {
        // Given
        let phonePrefix = "44"
        let phoneNumber = "1234567890"
        let verifyParams = HCaptchaVerifyParams(phonePrefix: phonePrefix, phoneNumber: phoneNumber, resetOnError: false)
        let command = HCaptchaWebViewManager.JSCommand.execute(verifyParams)

        // When
        let rawValue = command.rawValue

        // Then
        XCTAssertTrue(rawValue.contains("execute("))
        XCTAssertTrue(rawValue.contains("\"phonePrefix\":\"44\""))
        XCTAssertTrue(rawValue.contains("\"phoneNumber\":\"1234567890\""))
        XCTAssertTrue(rawValue.contains("\"resetOnError\":false"))
        XCTAssertTrue(rawValue.hasSuffix(");"))
    }

    func test__JSCommand_execute__withRqdata() {
        // Given
        let rqdata = "test-rqdata-string"
        let verifyParams = HCaptchaVerifyParams(rqdata: rqdata, resetOnError: false)
        let command = HCaptchaWebViewManager.JSCommand.execute(verifyParams)

        // When
        let rawValue = command.rawValue

        // Then
        XCTAssertTrue(rawValue.contains("execute("))
        XCTAssertTrue(rawValue.contains("\"rqdata\":\"test-rqdata-string\""))
        XCTAssertTrue(rawValue.contains("\"resetOnError\":false"))
        XCTAssertTrue(rawValue.hasSuffix(");"))
    }

    func test__JSCommand_reset() {
        // Given
        let command = HCaptchaWebViewManager.JSCommand.reset

        // When
        let rawValue = command.rawValue

        // Then
        XCTAssertEqual(rawValue, "reset();")
    }
}
