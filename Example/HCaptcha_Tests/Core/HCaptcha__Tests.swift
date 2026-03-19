//
//  HCaptcha__Tests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 26/09/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import AppSwizzle
@testable import HCaptcha
import RxSwift
import XCTest


class HCaptcha__Tests: XCTestCase {
    fileprivate struct Constants {
        struct InfoDictKeys {
            static let APIKey = "HCaptchaKey"
            static let Domain = "HCaptchaDomain"
        }
    }

    func test__valid_js_customTheme() {
        let customTheme = """
              {
                primary: {
                  main: "#00FF00"
                },
                text: {
                  heading: "#454545",
                  body   : "#8C8C8C"
                }
              }
            """
        do {
            _ = try HCaptcha(customTheme: customTheme)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }
    }

    func test__valid_json_customTheme() {
        let customTheme = """
              {
                "primary": {
                  "main": "#00FF00"
                },
                "text": {
                  "heading": "#454545",
                  "body"   : "#8C8C8C"
                }
              }
            """
        do {
            _ = try HCaptcha(customTheme: customTheme)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }
    }

    func test__invalid_js_customTheme() {
        let customTheme = """
              {
                primary: {
                  main: "#00FF00"
                },
                text: {
                  heading: "#454545",
                  body   : "#8C8C8C"
                }
              // } missing last bracket
            """
        do {
            _ = try HCaptcha(customTheme: customTheme)
            XCTFail("Should not be reached. Error expected")
        } catch let e as HCaptchaError {
            print(e)
            XCTAssertEqual(e, HCaptchaError.invalidCustomTheme)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }
    }

    func test__validate_from_didFinishLoading() {
        let exp = expectation(description: "execute js function must be called only once")
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}"))
        hcaptcha.didFinishLoading {
            let view = UIApplication.shared.windows.first?.rootViewController?.view
            hcaptcha.onEvent { e, _ in
                if e == .open {
                    exp.fulfill()
                }
            }
            hcaptcha.validate(on: view!) { _ in
                XCTFail("Should not be called")
            }
        }
        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__reconfigure() {
        let exp = expectation(description: "configureWebView called twice")
        var configureCounter = 0
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}"))
        hcaptcha.configureWebView { _ in
            configureCounter += 1
            if configureCounter == 2 {
                exp.fulfill()
            }
        }
        hcaptcha.didFinishLoading {
            let view = UIApplication.shared.windows.first?.rootViewController?.view
            hcaptcha.onEvent { e, _ in
                if e == .open {
                    hcaptcha.redrawView()
                }
            }
            hcaptcha.validate(on: view!) { _ in
                XCTFail("Should not be called")
            }
        }
        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__passiveSiteKey_configure_not_called() {
        let loaded = expectation(description: "hCaptcha WebView loaded")
        let tokenRecieved = expectation(description: "hCaptcha token recieved")
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{token: \"some_token\"}",
                                                                passiveApiKey: true))
        hcaptcha.configureWebView { _ in
            XCTFail("configureWebView should not be called for passive sitekey")
        }
        hcaptcha.didFinishLoading {
            loaded.fulfill()
        }
        let view = UIApplication.shared.windows.first!.rootViewController!.view!
        hcaptcha.validate(on: view) { result in
            XCTAssertEqual("some_token", result.token)
            tokenRecieved.fulfill()
        }
        wait(for: [loaded, tokenRecieved], timeout: TestTimeouts.standard)
    }

    func test__convenience_inits_is_not_recursive() throws {
        XCTAssertNotNil(try? HCaptcha(locale: Locale.current))
        XCTAssertNotNil(try? HCaptcha(size: .compact))
        XCTAssertNotNil(try? HCaptcha(passiveApiKey: true))
        XCTAssertNotNil(try? HCaptcha(apiKey: "10000000-ffff-ffff-ffff-000000000001"))
        XCTAssertNotNil(try? HCaptcha(apiKey: "10000000-ffff-ffff-ffff-000000000001",
                                      baseURL: URL(string: "http://localhost")!))
        XCTAssertNotNil(try? HCaptcha(apiKey: "10000000-ffff-ffff-ffff-000000000001",
                                      baseURL: URL(string: "http://localhost")!,
                                      locale: Locale.current))
        XCTAssertNotNil(try? HCaptcha(apiKey: "10000000-ffff-ffff-ffff-000000000001",
                                      baseURL: URL(string: "http://localhost")!,
                                      locale: Locale.current,
                                      size: .normal))
    }

    // MARK: - Verify Params Tests

    func test__validate__withVerifyParams__phonePrefix() {
        // Given
        let exp = expectation(description: "validate with phone prefix")
        let phonePrefix = "44"
        let verifyParams = HCaptchaVerifyParams(phonePrefix: phonePrefix)
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{token: \"test_token\"}"))

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
            // Then
            XCTAssertEqual(result.token, "test_token")
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withVerifyParams__phoneNumber() {
        // Given
        let exp = expectation(description: "validate with phone number")
        let phoneNumber = "+1234567890"
        let verifyParams = HCaptchaVerifyParams(phoneNumber: phoneNumber)
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{token: \"test_token\"}"))

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
            // Then
            XCTAssertEqual(result.token, "test_token")
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withVerifyParams__bothPhoneValues() {
        // Given
        let exp = expectation(description: "validate with both phone values")
        let phonePrefix = "44"
        let phoneNumber = "1234567890"
        let verifyParams = HCaptchaVerifyParams(phonePrefix: phonePrefix, phoneNumber: phoneNumber)
        let manager = HCaptchaWebViewManager(html: instrumentedSetDataHTML(), apiKey: "api-key")
        let hcaptcha = HCaptcha(manager: manager)

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
            // Then
            let payload = self.setDataPayload(from: result)
            XCTAssertEqual(payload["mfa_phoneprefix"] as? String, phonePrefix)
            XCTAssertEqual(payload["mfa_phone"] as? String, phoneNumber)
            XCTAssertNil(payload["phonePrefix"])
            XCTAssertNil(payload["phoneNumber"])
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withVerifyParams__rqdata() {
        // Given
        let exp = expectation(description: "validate with rqdata")
        let rqdata = "test-rqdata-string"
        let verifyParams = HCaptchaVerifyParams(rqdata: rqdata)
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{token: \"test_token\"}"))

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
            // Then
            XCTAssertEqual(result.token, "test_token")
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withVerifyParams__rqdataReachesJSOnInitialLoad() {
        // Given
        let exp = expectation(description: "rqdata is forwarded to JS on initial load")
        let rqdata = "test-rqdata-string"
        let verifyParams = HCaptchaVerifyParams(rqdata: rqdata)
        let manager = HCaptchaWebViewManager(html: instrumentedSetDataHTML(), apiKey: "api-key")
        let hcaptcha = HCaptcha(manager: manager)

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
            // Then
            let payload = self.setDataPayload(from: result)
            XCTAssertEqual(payload["rqdata"] as? String, rqdata)
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withDeprecatedRqdata__reachesJSOnInitialLoad() {
        // Given
        let exp = expectation(description: "deprecated rqdata is forwarded to JS on initial load")
        let rqdata = "deprecated-rqdata-string"
        let manager = HCaptchaWebViewManager(html: instrumentedSetDataHTML(),
                                             apiKey: "api-key",
                                             rqdata: rqdata)
        let hcaptcha = HCaptcha(manager: manager)

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view) { result in
            // Then
            let payload = self.setDataPayload(from: result)
            XCTAssertEqual(payload["rqdata"] as? String, rqdata)
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withDeprecatedRqdata__verifyParamsOverrideFallback() {
        // Given
        let exp = expectation(description: "verify params rqdata overrides deprecated fallback")
        let deprecatedRqdata = "deprecated-rqdata-string"
        let verifyRqdata = "verify-rqdata-string"
        let manager = HCaptchaWebViewManager(html: instrumentedSetDataHTML(),
                                             apiKey: "api-key",
                                             rqdata: deprecatedRqdata)
        let hcaptcha = HCaptcha(manager: manager)
        let verifyParams = HCaptchaVerifyParams(rqdata: verifyRqdata)

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
            // Then
            let payload = self.setDataPayload(from: result)
            XCTAssertEqual(payload["rqdata"] as? String, verifyRqdata)
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withVerifyParams__resetOnErrorFalse() {
        // Given
        let exp = expectation(description: "validate with resetOnError false")
        let phonePrefix = "44"
        let verifyParams = HCaptchaVerifyParams(phonePrefix: phonePrefix, resetOnError: false)
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{token: \"test_token\"}"))

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
            // Then
            XCTAssertEqual(result.token, "test_token")
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withVerifyParams__nilValues() {
        // Given
        let exp = expectation(description: "validate with nil phone values")
        let verifyParams = HCaptchaVerifyParams()
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{token: \"test_token\"}"))

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
            // Then
            XCTAssertEqual(result.error, .verifyParamsParseError)
            XCTAssertNil(result.token)
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withVerifyParams__callsManagerCorrectly() {
        // Given
        let exp = expectation(description: "manager receives verify params")
        let phonePrefix = "44"
        let verifyParams = HCaptchaVerifyParams(phonePrefix: phonePrefix)

        // Create a mock manager that we can inspect
        class MockManager: HCaptchaWebViewManager {
            var receivedVerifyParams: HCaptchaVerifyParams?
            var receivedResetOnError: Bool?

            override func validate(on view: UIView?) {
                receivedVerifyParams = self.verifyParams
                receivedResetOnError = self.shouldResetOnError
                super.validate(on: view)
            }
        }

        let mockManager = MockManager(messageBody: "{token: \"test_token\"}")
        let hcaptcha = HCaptcha(manager: mockManager)

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { _ in
            // Then
            XCTAssertEqual(mockManager.receivedVerifyParams?.phonePrefix, phonePrefix)
            XCTAssertTrue(mockManager.receivedResetOnError ?? false)
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withVerifyParams__setsResetOnError() {
        // Given
        let exp = expectation(description: "resetOnError is set correctly")
        let phonePrefix = "44"
        let resetOnError = false
        let verifyParams = HCaptchaVerifyParams(phonePrefix: phonePrefix, resetOnError: resetOnError)

        // Create a mock manager that we can inspect
        class MockManager: HCaptchaWebViewManager {
            var receivedResetOnError: Bool?

            override func validate(on view: UIView?) {
                receivedResetOnError = self.shouldResetOnError
                super.validate(on: view)
            }
        }

        let mockManager = MockManager(messageBody: "{token: \"test_token\"}")
        let hcaptcha = HCaptcha(manager: mockManager)

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { _ in
            // Then
            XCTAssertEqual(mockManager.receivedResetOnError, resetOnError)
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withUserJourney__allowsInternalVerifyParams() {
        // Given
        let exp = expectation(description: "userJourney payload is injected on default validate path")

        class MockManager: HCaptchaWebViewManager {
            var receivedVerifyParams: HCaptchaVerifyParams?

            override func validate(on view: UIView?) {
                receivedVerifyParams = self.verifyParams
                let completion = self.completion
                self.completion = nil
                stop()
                completion?(HCaptchaResult(self, token: "test_token"))
            }
        }

        let manager = MockManager(messageBody: "{token: \"fallback_token\"}")
        let hcaptcha = HCaptcha(manager: manager, userJourney: true)

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view) { result in
            // Then
            XCTAssertNil(result.error)
            XCTAssertEqual(result.token, "test_token")
            XCTAssertNotNil(manager.receivedVerifyParams)
            XCTAssertNotNil(manager.receivedVerifyParams?.userJourney as? [Any])
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    // MARK: - User Journeys Tests
    // To run manually once Journeylitics subspec removed from test target app
    func test__userJourney_enabled_without_impl_throws() {
        do {
            _ = try HCaptcha(userJourney: true)
            XCTFail("Expected journeyliticsNotAvailable error when Journeylitics impl is not linked")
        } catch let error as HCaptchaError {
            XCTAssertEqual(error, .journeyliticsNotAvailable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private extension HCaptcha__Tests {
    func instrumentedSetDataHTML(file: StaticString = #filePath, line: UInt = #line) -> String {
        let html = HCaptchaHtml.template.replacingOccurrences(
            of: "document.head.appendChild(script);",
            with: """
              window.hcaptcha = {
                setData: function(_, data) {
                  window.__setDataPayload = data;
                },
                execute: function() {
                  post({ token: JSON.stringify(window.__setDataPayload || null) });
                },
                reset: function() {
                  post({ action: "didLoad" });
                },
                render: function() {
                  return 1;
                },
                close: function() {}
              };

              setTimeout(function() {
                onloadCallback();
              }, 0);
            """
        )

        XCTAssertNotEqual(
            html,
            HCaptchaHtml.template,
            "failed to instrument setData test HTML",
            file: file,
            line: line
        )

        return html
    }

    func setDataPayload(from result: HCaptchaResult,
                        file: StaticString = #filePath,
                        line: UInt = #line) -> [String: Any] {
        XCTAssertNil(result.error, file: file, line: line)

        guard let token = result.token,
              let data = token.data(using: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("expected setData payload token", file: file, line: line)
            return [:]
        }

        return payload
    }
}


private extension Bundle {
    @objc func failHTMLLoad(_ resource: String, type: String) -> String? {
        guard resource == "hcaptcha" && type == "html" else {
            return failHTMLLoad(resource, type: type)
        }

        return nil
    }
}
