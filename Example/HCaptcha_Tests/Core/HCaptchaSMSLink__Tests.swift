//
//  HCaptchaSMSLink__Tests.swift
//  HCaptcha
//
//  Copyright © 2026 HCaptcha. All rights reserved.
//

@testable import HCaptcha

import XCTest

class HCaptchaSMSLink__Tests: XCTestCase {

    private func parse(_ string: String, file: StaticString = #file, line: UInt = #line) -> HCaptchaSMSLink? {
        guard let url = URL(string: string) else {
            XCTFail("not a valid URL: \(string)", file: file, line: line)
            return nil
        }
        return HCaptchaSMSLink(url: url)
    }

    func test__Rejects_Non_SMS_Schemes() {
        for string in ["https://hcaptcha.com?body=code", "tel:+15551234567", "mailto:support@hcaptcha.com?body=code"] {
            XCTAssertNil(parse(string), string)
        }
    }

    func test__Parses_SMS_Links() {
        let cases: [(url: String, recipient: String?, body: String?)] = [
            // The shape the live MFA challenge emits. The code must survive byte-exact:
            // hCaptcha matches on it, and the hyphens are part of what the user sends.
            ("sms:+46769439873?body=Return%20to%20the%20app%3A%20gsuc-djcd-wd6z",
             "+46769439873", "Return to the app: gsuc-djcd-wd6z"),

            // RFC 5724 subscriber parameters precede the query and must not swallow it
            ("sms:+15551234567;phone-context=+1?body=123456", "+15551234567", "123456"),
            ("sms:+15551234567;body=123456", "+15551234567", "123456"),

            // Separators are decoded after splitting, and a `;` in a query is body text
            ("sms:+15551234567?body=a%26b%3Dc%3Bd", "+15551234567", "a&b=c;d"),
            ("sms:+15551234567?body=hi;there", "+15551234567", "hi;there"),
            // `+` is a literal plus in a URI query, never a space
            ("sms:+15551234567?body=a+b", "+15551234567", "a+b"),

            // Recipient: normalized for the composer, percent-decoded, extras dropped
            ("sms:+1 (555) 123-4567", "+15551234567", nil),
            ("sms:%2B15551234567,+15559999999?body=x", "+15551234567", "x"),

            // Parameter lookup
            ("sms:+15551234567?foo=bar&BODY=123456", "+15551234567", "123456"),
            ("sms:+15551234567?foo=bar", "+15551234567", nil),
            ("sms:+15551234567?body=", "+15551234567", nil),

            // Degenerate, but still sms: links
            ("sms:", nil, nil),
            ("sms:?body=code", nil, "code"),
            ("sms://+15551234567?body=code", "+15551234567", "code")
        ]

        for (string, recipient, body) in cases {
            let link = parse(string)
            XCTAssertNotNil(link, string)
            XCTAssertEqual(link?.recipient, recipient, string)
            XCTAssertEqual(link?.body, body, string)
        }
    }
}
