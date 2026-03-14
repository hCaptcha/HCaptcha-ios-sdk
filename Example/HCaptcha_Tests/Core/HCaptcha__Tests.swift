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
        let html = """
        <html>
          <head>
            <script type="text/javascript">
              var post = function(value) {
                window.webkit.messageHandlers.hcaptcha.postMessage(value);
              };

              var execute = function(verifyParams) {
                if (verifyParams && verifyParams.rqdata) {
                  post({ token: verifyParams.rqdata });
                } else {
                  post({ error: 34 });
                }
              };

              var reset = function() {
                post({ action: "didLoad" });
              };

              post({ action: "didLoad" });
            </script>
          </head>
          <body></body>
        </html>
        """
        let manager = HCaptchaWebViewManager(html: html, apiKey: "api-key")
        let hcaptcha = HCaptcha(manager: manager)

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
            // Then
            XCTAssertNil(result.error)
            XCTAssertEqual(result.token, rqdata)
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withDeprecatedRqdata__reachesJSOnInitialLoad() {
        // Given
        let exp = expectation(description: "deprecated rqdata is forwarded to JS on initial load")
        let rqdata = "deprecated-rqdata-string"
        let manager = HCaptchaWebViewManager(html: deprecatedRqdataHTML,
                                             apiKey: "api-key",
                                             rqdata: rqdata)
        let hcaptcha = HCaptcha(manager: manager)

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view) { result in
            // Then
            XCTAssertNil(result.error)
            XCTAssertEqual(result.token, rqdata)
            exp.fulfill()
        }

        wait(for: [exp], timeout: TestTimeouts.standard)
    }

    func test__validate__withDeprecatedRqdata__verifyParamsOverrideFallback() {
        // Given
        let exp = expectation(description: "verify params rqdata overrides deprecated fallback")
        let deprecatedRqdata = "deprecated-rqdata-string"
        let verifyRqdata = "verify-rqdata-string"
        let manager = HCaptchaWebViewManager(html: deprecatedRqdataHTML,
                                             apiKey: "api-key",
                                             rqdata: deprecatedRqdata)
        let hcaptcha = HCaptcha(manager: manager)
        let verifyParams = HCaptchaVerifyParams(rqdata: verifyRqdata)

        // When
        let view = UIApplication.shared.windows.first?.rootViewController?.view
        hcaptcha.validate(on: view, verifyParams: verifyParams) { result in
            // Then
            XCTAssertNil(result.error)
            XCTAssertEqual(result.token, verifyRqdata)
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
}

private extension HCaptcha__Tests {
    var deprecatedRqdataHTML: String {
        """
        <html>
          <head>
            <script type="text/javascript">
              var post = function(value) {
                window.webkit.messageHandlers.hcaptcha.postMessage(value);
              };

              var capturedData = null;
              var hcaptcha = {
                render: function() {
                  return 1;
                },
                setData: function(_, data) {
                  capturedData = data;
                },
                execute: function() {
                  if (capturedData && capturedData.rqdata) {
                    post({ token: capturedData.rqdata });
                  } else {
                    post({ error: 34 });
                  }
                },
                reset: function() {
                  post({ action: "didLoad" });
                }
              };
              window.hcaptcha = hcaptcha;

              var setVerifyParams = function(params) {
                try {
                  var phone = params.phoneNumber || params.mfa_phone;
                  var prefix = params.phonePrefix || params.mfa_phoneprefix;
                  var rqdata = params.rqdata || "${rqdata}";

                  if (phone || prefix || rqdata) {
                    var data = {};
                    if (phone) data.mfa_phone = phone;
                    if (prefix) data.mfa_phoneprefix = prefix;
                    if (rqdata) data.rqdata = rqdata;

                    if (window.hCaptchaID) {
                      hcaptcha.setData(window.hCaptchaID, data);
                    }
                  }
                } catch (e) {
                  post({ error: 34 });
                }
              };

              var execute = function(verifyParams) {
                try {
                  if (verifyParams || "${rqdata}") {
                    setVerifyParams(verifyParams || {});
                  }
                  hcaptcha.execute();
                } catch (e) {
                  post({ error: 29 });
                }
              };

              var reset = function() {
                hcaptcha.reset();
              };

              window.hCaptchaID = hcaptcha.render("hcaptcha-container", {});
              post({ action: "didLoad" });
            </script>
          </head>
          <body>
            <div id="hcaptcha-container"></div>
          </body>
        </html>
        """
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
