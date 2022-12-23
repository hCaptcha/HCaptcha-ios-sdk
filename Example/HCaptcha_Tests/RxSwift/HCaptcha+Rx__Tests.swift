//
//  HCaptcha+Rx__Tests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 13/04/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@testable import HCaptcha

import RxBlocking
import RxCocoa
import RxSwift
import XCTest


class HCaptcha_Rx__Tests: XCTestCase {

    fileprivate var apiKey: String!
    fileprivate var presenterView: UIView!

    override func setUp() {
        super.setUp()

        presenterView = UIApplication.shared.keyWindow!
        apiKey = String(arc4random())
    }

    override func tearDown() {
        presenterView = nil
        apiKey = nil

        super.tearDown()
    }


    func test__Validate__Token() {
        let exp = expectation(description: "should call configureWebView")
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey))
        hcaptcha.configureWebView { _ in
            exp.fulfill()
        }

        do {
            // Validate
            let result = try hcaptcha.rx.validate(on: presenterView)
                .toBlocking()
                .single()

            // Verify
            XCTAssertEqual(result, apiKey)
        }
        catch let error {
            XCTFail(error.localizedDescription)
        }
        waitForExpectations(timeout: 5)
    }


    func test__Validate__Show_HCaptcha() {
        let hcaptcha = HCaptcha(
            manager: HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}", apiKey: apiKey)
        )

        let exp = expectation(description: "should call configureWebView")

        hcaptcha.configureWebView { _ in
            exp.fulfill()
        }

        do {
            // Validate
            _ = try hcaptcha.rx.validate(on: presenterView)
                .toBlocking(timeout: 2)
                .single()

            XCTFail("should have thrown exception")
        }
        catch let error {
            waitForExpectations(timeout: 5)
            XCTAssertEqual(String(describing: error), RxError.timeout.debugDescription)
        }
    }


    func test__Validate__Error() {
        let exp = expectation(description: "should call configureWebView")
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "\"foobar\"", apiKey: apiKey))
        hcaptcha.configureWebView { _ in
            exp.fulfill()
        }

        do {
            // Validate
            _ = try hcaptcha.rx.validate(on: presenterView, resetOnError: false)
                .toBlocking()
                .single()

            XCTFail("should have thrown exception")
        }
        catch let error {
            XCTAssertEqual(error as? HCaptchaError, .wrongMessageFormat)
        }
        waitForExpectations(timeout: 0)
    }

    // MARK: - Did Finish Loading

    func test__Did_Finish_Loading__Immediate() {
        let manager = HCaptchaWebViewManager()
        let hcaptcha = HCaptcha(manager: manager)

        manager.onDidFinishLoading = {
            do {
                try hcaptcha.rx.didFinishLoading
                    .toBlocking()
                    .first()
            }
            catch let error {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func test__Did_Finish_Loading__Multiple() {
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager())

        do {
            let obs = hcaptcha.rx.didFinishLoading
                .take(2)
                .share()

            let reset = obs.do(onNext: hcaptcha.reset).subscribe()

            let result: [Void] = try obs
                .toBlocking()
                .toArray()

            XCTAssertEqual(result.count, 2)
            reset.dispose()
        }
        catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test__Did_Finish_Loading__Delayed() {
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(shouldFail: true))

        do {
            _ = try hcaptcha.rx.didFinishLoading
                .toBlocking(timeout: 0.1)
                .first()

            XCTFail("should have timed out")
        }
        catch let error {
            XCTAssertEqual(String(describing: error), RxError.timeout.debugDescription)
        }

        do {
            hcaptcha.reset()

            try hcaptcha.rx.didFinishLoading
                .toBlocking()
                .first()
        }
        catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test__Did_Finish_Loading__Dispose() {
        let manager = HCaptchaWebViewManager()
        let hcaptcha = HCaptcha(manager: manager)

        let obs = hcaptcha.rx.didFinishLoading
            .subscribe()

        XCTAssertNotNil(manager.onDidFinishLoading)

        obs.dispose()
        XCTAssertNil(manager.onDidFinishLoading)
    }

    // MARK: - Dispose

    func test__Dispose() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "stop loading")

        // Stop
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{log: \"foo\"}"))
        hcaptcha.configureWebView { _ in
            exp0.fulfill()
        }

        let disposable = hcaptcha.rx.validate(on: presenterView)
            .do(onDispose: exp1.fulfill)
            .subscribe { _ in
                XCTFail("should not validate")
            }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: disposable.dispose)

        waitForExpectations(timeout: 10)
    }

    // MARK: - Reset

    func test__Reset() {
        var expCount = 0
        let exp = expectation(description: "should call configureWebView")

        // Validate
        let hcaptcha = HCaptcha(
            manager: HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey, shouldFail: true)
        )

        hcaptcha.configureWebView { _ in
            expCount += 1
            if expCount == 2 {
                exp.fulfill()
            }
        }

        do {
            // Error
            _ = try hcaptcha.rx.validate(on: presenterView, resetOnError: false)
                .toBlocking()
                .single()
        }
        catch let error {
            XCTAssertEqual(error as? HCaptchaError, .wrongMessageFormat)

            // Resets after failure
            _ = Observable<Void>.just(())
                .bind(to: hcaptcha.rx.reset)
        }

        do {
            // Resets and tries again
            let result = try hcaptcha.rx.validate(on: presenterView, resetOnError: false)
                .toBlocking()
                .single()

            XCTAssertEqual(result, apiKey)
        }
        catch let error {
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 0)
    }

    func test__Validate__Reset_On_Error() {
        var expCount = 0
        let exp = expectation(description: "should call configureWebView")

        // Validate
        let hcaptcha = HCaptcha(
            manager: HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey, shouldFail: true)
        )

        hcaptcha.configureWebView { _ in
            expCount += 1
            if expCount == 2 {
                exp.fulfill()
            }
        }

        do {
            // Error
            let result = try hcaptcha.rx.validate(on: presenterView, resetOnError: true)
                .toBlocking()
                .single()

            XCTAssertEqual(result, apiKey)
        }
        catch let error {
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 0)
    }
}
