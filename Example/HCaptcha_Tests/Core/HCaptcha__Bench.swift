//
//  HCaptcha__Bench.swift
//  HCaptcha_Tests
//
//  Copyright © 2022 HCaptcha. All rights reserved.
//

import Foundation
import XCTest
@testable import HCaptcha

class HCaptcha__Bench: XCTestCase {
    override func setUp() {
        HCaptchaHtml.template = """
            <html>
              <head>
                <meta name="viewport" content="width=device-width" />
                <script type="text/javascript">
                  var apiKey = "${apiKey}";
                  var endpoint = "${endpoint}";
                  var rqdata = "${rqdata}";
                  var theme = ${theme};
                  var debugInfo = JSON.parse('${debugInfo}');

                  console.assert(typeof apiKey === "string", "invalid apiKey");
                  console.assert(typeof endpoint === "string", "invalid endpoint");
                  console.assert(typeof rqdata === "string", "invalid rqdata");
                  console.assert(["string", "object"].includes(typeof theme), "invalid theme object");
                  console.assert(Array.isArray(debugInfo), "invalid type");

                  var post = function(value) {
                    window.webkit.messageHandlers.hcaptcha.postMessage(value);
                  };

                  var execute = function() {
                    post({ token: "bench-token" });
                  };

                  var reset = function() {
                    post({ action: "didLoad" });
                  };

                  post({ action: "didLoad" });
                </script>
              </head>
              <body>
                <div id="hcaptcha-container">
              </body>
            </html>
        """
    }

    let options: XCTMeasureOptions = {
        var result = XCTMeasureOptions()
        result.iterationCount = 3
        result.invocationOptions = .manuallyStop
        return result
    }()

    let apiKey = "10000000-ffff-ffff-ffff-000000000001"

    func testBenchInit() throws {
        self.measure {
            _ = try? HCaptcha(apiKey: apiKey, size: .invisible)
            self.stopMeasuring()
        }
    }

    func testBenchColdrun() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 600))
        self.measure(options: XCTMeasureOptions(), block: {
            let hcaptcha = try? HCaptcha(apiKey: apiKey, size: .invisible)
            hcaptcha?.validate(on: view, completion: { _ in
                self.stopMeasuring()
            })
        })
    }

    func testBenchVerify() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 600))
        let hcaptcha = try? HCaptcha(apiKey: apiKey, size: .invisible)
        self.measure {
            hcaptcha?.validate(on: view, completion: { _ in
                self.stopMeasuring()
            })
        }
    }
}
