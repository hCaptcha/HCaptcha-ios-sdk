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

    func test__Debug_Info_Has_Expected_Signals() throws {
        let data = try XCTUnwrap(HCaptchaDebugInfo.json.data(using: .utf8))
        let debugInfo = try JSONDecoder().decode([String].self, from: data)

        XCTAssertEqual(debugInfo.count, 5)
        XCTAssertTrue(debugInfo[0].hasPrefix("sys_"))
        XCTAssertTrue(debugInfo[1].hasPrefix("deps_"))
        XCTAssertTrue(debugInfo[2].hasPrefix("app_"))
        XCTAssertTrue(debugInfo[3].hasPrefix("iver_"))
        XCTAssertTrue(debugInfo[4].hasPrefix("sdk_"))
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

    // MARK: - HCaptchaConfig Tests

    func test__config_defaults_match_legacy_init_defaults() {
        let config = HCaptchaConfig()

        XCTAssertNil(config.apiKey)
        XCTAssertFalse(config.passiveApiKey)
        XCTAssertNil(config.baseURL)
        XCTAssertEqual(config.locale, Locale.current)
        XCTAssertEqual(config.size, .invisible)
        XCTAssertEqual(config.orientation, .portrait)
        XCTAssertEqual(config.jsSrc, URL(string: "https://js.hcaptcha.com/1/api.js")!)
        XCTAssertFalse(config.sentry)
        XCTAssertNil(config.endpoint)
        XCTAssertNil(config.reportapi)
        XCTAssertNil(config.assethost)
        XCTAssertNil(config.imghost)
        XCTAssertNil(config.host)
        XCTAssertEqual(config.theme, "light")
        XCTAssertNil(config.customTheme)
        XCTAssertFalse(config.diagnosticLog)
        XCTAssertFalse(config.disableDebugInfo)
        XCTAssertFalse(config.disablePat)
        XCTAssertFalse(config.userJourney)
        XCTAssertNil(config.rqdata)
    }

    func test__config_convenience_inits() {
        let url = URL(string: "http://localhost")!

        let config1 = HCaptchaConfig(apiKey: "10000000-ffff-ffff-ffff-000000000001")
        XCTAssertEqual(config1.apiKey, "10000000-ffff-ffff-ffff-000000000001")
        XCTAssertNil(config1.baseURL)

        let config2 = HCaptchaConfig(apiKey: "10000000-ffff-ffff-ffff-000000000001", baseURL: url)
        XCTAssertEqual(config2.apiKey, "10000000-ffff-ffff-ffff-000000000001")
        XCTAssertEqual(config2.baseURL, url)
    }

    func test__init_with_config() {
        XCTAssertNotNil(try? HCaptcha(config: HCaptchaConfig()))

        let config = HCaptchaConfig(apiKey: "10000000-ffff-ffff-ffff-000000000001",
                                    baseURL: URL(string: "http://localhost")!)
        config.size = .compact
        config.theme = "dark"
        XCTAssertNotNil(try? HCaptcha(config: config))
    }

    func test__init_with_config_validates_params() {
        let invalidHost = HCaptchaConfig()
        invalidHost.host = "https://example.com/path"
        XCTAssertThrowsError(try HCaptcha(config: invalidHost)) { error in
            XCTAssertEqual(error as? HCaptchaError, .invalidHostFormat)
        }

        let invalidTheme = HCaptchaConfig()
        invalidTheme.customTheme = "[Object object]"
        XCTAssertThrowsError(try HCaptcha(config: invalidTheme)) { error in
            XCTAssertEqual(error as? HCaptchaError, .invalidCustomTheme)
        }
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

    func test__validate__setDataFailure__doesNotStartChallenge() {
        for size in [HCaptchaSize.invisible, .compact] {
            for useDeprecatedRqdata in [false, true] {
                let exp = expectation(description: "setData failure stops challenge: \(size), \(useDeprecatedRqdata)")
                let manager = HCaptchaWebViewManager(
                    html: instrumentedSetDataHTML(setDataThrows: true),
                    apiKey: "api-key",
                    size: size,
                    rqdata: useDeprecatedRqdata ? "test-rqdata" : nil
                )
                let hcaptcha = HCaptcha(manager: manager)
                let view = UIApplication.shared.windows.first?.rootViewController?.view
                let completion: (HCaptchaResult) -> Void = { result in
                    XCTAssertEqual(result.error, .verifyParamsParseError)
                    XCTAssertNil(result.token)
                    manager.webView.evaluateJavaScript(
                        """
                        [window.__setDataCalls || 0, window.__executeCalls || 0,
                         window.__messages.filter(function(message) {
                           return message.action === "showHCaptcha";
                         }).length,
                         window.__messages.filter(function(message) {
                           return message.error !== undefined;
                         }).length]
                        """
                    ) { value, error in
                        XCTAssertNil(error)
                        XCTAssertEqual(value as? [Int], [1, 0, 0, 1])
                        XCTAssertTrue(manager.webView.isHidden)
                        exp.fulfill()
                    }
                }

                if useDeprecatedRqdata {
                    hcaptcha.validate(on: view, completion: completion)
                } else {
                    hcaptcha.validate(on: view,
                                      verifyParams: HCaptchaVerifyParams(rqdata: "test-rqdata"),
                                      completion: completion)
                }

                wait(for: [exp], timeout: TestTimeouts.standard)
            }
        }
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
    func instrumentedSetDataHTML(setDataThrows: Bool = false,
                                 file: StaticString = #filePath, line: UInt = #line) -> String {
        let html = HCaptchaHtml.template.replacingOccurrences(
            of: "document.head.appendChild(script);",
            with: """
              window.hcaptcha = {
                setData: function(_, data) {
                  window.__setDataCalls = (window.__setDataCalls || 0) + 1;
                  if (\(setDataThrows)) { throw new Error("setData failed"); }
                  window.__setDataPayload = data;
                },
                execute: function() {
                  window.__executeCalls = (window.__executeCalls || 0) + 1;
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
                window.__messages = [];
                var originalPost = post;
                post = function(message) {
                  window.__messages.push(message);
                  originalPost(message);
                };
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
