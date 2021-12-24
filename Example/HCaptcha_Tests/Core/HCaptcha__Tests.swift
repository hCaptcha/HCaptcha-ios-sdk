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

    func test__Fails_Without_HTML_File() {
        _ = Bundle.swizzleInstanceMethod(
            origSelector: #selector(Bundle.path(forResource:ofType:)),
            toAlterSelector: #selector(Bundle.failHTMLLoad(_:type:))
        )

        do {
            _ = try HCaptcha()
            XCTFail("Should have failed")
        } catch let e as HCaptchaError {
            print(e)
            XCTAssertEqual(e, HCaptchaError.htmlLoadError)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }

        // Unswizzle
        _ = Bundle.swizzleInstanceMethod(
            origSelector: #selector(Bundle.path(forResource:ofType:)),
            toAlterSelector: #selector(Bundle.failHTMLLoad(_:type:))
        )
    }

    // TODO most of the tests below belong to Config class not to HCaptcha class
    // so move it to proper file

    func test__Base_URL() {
        // Ensures baseURL failure when nil
        do {
            _ = try HCaptcha.Config(apiKey: "", infoPlistKey: nil, baseURL: nil, infoPlistURL: nil)
            XCTFail("Should have failed")
        } catch let e as HCaptchaError {
            print(e)
            XCTAssertEqual(e, HCaptchaError.baseURLNotFound)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }

        // Ensures plist url if nil key
        let plistURL = URL(string: "https://bar")!
        let config1 = try? HCaptcha.Config(apiKey: "", infoPlistKey: nil, baseURL: nil, infoPlistURL: plistURL)
        XCTAssertEqual(config1?.baseURL, plistURL)

        // Ensures preference of given url over plist entry
        let url = URL(string: "ftp://foo")!
        let config2 = try? HCaptcha.Config(apiKey: "", infoPlistKey: nil, baseURL: url, infoPlistURL: plistURL)
        XCTAssertEqual(config2?.baseURL, url)
    }

    func test__Base_URL_Without_Scheme() {
        // Ignores URL with scheme
        let goodURL = URL(string: "https://foo.bar")!
        let config0 = try? HCaptcha.Config(apiKey: "", infoPlistKey: nil, baseURL: goodURL, infoPlistURL: nil)
        XCTAssertEqual(config0?.baseURL, goodURL)

        // Fixes URL without scheme
        let badURL = URL(string: "foo")!
        let config = try? HCaptcha.Config(apiKey: "", infoPlistKey: nil, baseURL: badURL, infoPlistURL: nil)
        XCTAssertEqual(config?.baseURL.absoluteString, "http://" + badURL.absoluteString)
    }

    func test__API_Key() {
        // Ensures key failure when nil
        do {
            _ = try HCaptcha.Config(apiKey: nil, infoPlistKey: nil, baseURL: nil, infoPlistURL: nil)
            XCTFail("Should have failed")
        } catch let e as HCaptchaError {
            print(e)
            XCTAssertEqual(e, HCaptchaError.apiKeyNotFound)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }

        // Ensures plist key if nil key
        let plistKey = "bar"
        let config1 = try? HCaptcha.Config(
            apiKey: nil,
            infoPlistKey: plistKey,
            baseURL: URL(string: "foo"),
            infoPlistURL: nil
        )
        XCTAssertEqual(config1?.apiKey, plistKey)

        // Ensures preference of given key over plist entry
        let key = "foo"
        let config2 = try? HCaptcha.Config(
            apiKey: key,
            infoPlistKey: plistKey,
            baseURL: URL(string: "foo"),
            infoPlistURL: nil
        )
        XCTAssertEqual(config2?.apiKey, key)
    }

    func test__Force_Visible_Challenge() {
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager())

        // Initial value
        XCTAssertFalse(hcaptcha.forceVisibleChallenge)

        // Set true
        hcaptcha.forceVisibleChallenge = true
        XCTAssertTrue(hcaptcha.forceVisibleChallenge)
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
}


private extension Bundle {
    @objc func failHTMLLoad(_ resource: String, type: String) -> String? {
        guard resource == "hcaptcha" && type == "html" else {
            return failHTMLLoad(resource, type: type)
        }

        return nil
    }
}
