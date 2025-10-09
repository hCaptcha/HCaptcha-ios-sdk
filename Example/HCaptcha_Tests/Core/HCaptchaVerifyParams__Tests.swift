//
//  HCaptchaVerifyParams__Tests.swift
//  HCaptcha
//
//  Created by Assistant on 26/09/25.
//  Copyright © 2025 HCaptcha. All rights reserved.
//

@testable import HCaptcha
import XCTest

class HCaptchaVerifyParams__Tests: XCTestCase {

    // MARK: - Initialization Tests

    func test__init__defaultValues() {
        // Given/When
        let params = HCaptchaVerifyParams()

        // Then
        XCTAssertNil(params.phonePrefix)
        XCTAssertNil(params.phoneNumber)
        XCTAssertTrue(params.resetOnError)
    }

    func test__init__withPhonePrefix() {
        // Given
        let phonePrefix = "44"

        // When
        let params = HCaptchaVerifyParams(phonePrefix: phonePrefix)

        // Then
        XCTAssertEqual(params.phonePrefix, phonePrefix)
        XCTAssertNil(params.phoneNumber)
        XCTAssertTrue(params.resetOnError)
    }

    func test__init__withPhoneNumber() {
        // Given
        let phoneNumber = "+1234567890"

        // When
        let params = HCaptchaVerifyParams(phoneNumber: phoneNumber)

        // Then
        XCTAssertNil(params.phonePrefix)
        XCTAssertEqual(params.phoneNumber, phoneNumber)
        XCTAssertTrue(params.resetOnError)
    }

    func test__init__withBothPhoneValues() {
        // Given
        let phonePrefix = "44"
        let phoneNumber = "1234567890"

        // When
        let params = HCaptchaVerifyParams(phonePrefix: phonePrefix, phoneNumber: phoneNumber)

        // Then
        XCTAssertEqual(params.phonePrefix, phonePrefix)
        XCTAssertEqual(params.phoneNumber, phoneNumber)
        XCTAssertTrue(params.resetOnError)
    }

    func test__init__withRqdata() {
        // Given
        let rqdata = "test-rqdata-string"

        // When
        let params = HCaptchaVerifyParams(rqdata: rqdata)

        // Then
        XCTAssertNil(params.phonePrefix)
        XCTAssertNil(params.phoneNumber)
        XCTAssertEqual(params.rqdata, rqdata)
        XCTAssertTrue(params.resetOnError)
    }

    func test__init__withAllValues() {
        // Given
        let phonePrefix = "44"
        let phoneNumber = "1234567890"
        let rqdata = "test-rqdata-string"
        let resetOnError = false

        // When
        let params = HCaptchaVerifyParams(phonePrefix: phonePrefix,
                                         phoneNumber: phoneNumber,
                                         rqdata: rqdata,
                                         resetOnError: resetOnError)

        // Then
        XCTAssertEqual(params.phonePrefix, phonePrefix)
        XCTAssertEqual(params.phoneNumber, phoneNumber)
        XCTAssertEqual(params.rqdata, rqdata)
        XCTAssertFalse(params.resetOnError)
    }

    func test__init__withResetOnError() {
        // Given
        let phonePrefix = "44"
        let resetOnError = false

        // When
        let params = HCaptchaVerifyParams(phonePrefix: phonePrefix, resetOnError: resetOnError)

        // Then
        XCTAssertEqual(params.phonePrefix, phonePrefix)
        XCTAssertNil(params.phoneNumber)
        XCTAssertFalse(params.resetOnError)
    }


    // MARK: - toDictionary Tests

    func test__toDictionary__withAllValues() {
        // Given
        let phonePrefix = "44"
        let phoneNumber = "1234567890"
        let rqdata = "test-rqdata"
        let resetOnError = false
        let params = HCaptchaVerifyParams(phonePrefix: phonePrefix,
                                         phoneNumber: phoneNumber,
                                         rqdata: rqdata,
                                         resetOnError: resetOnError)

        // When
        let dict = params.toDictionary()

        // Then
        XCTAssertEqual(dict["phonePrefix"] as? String, phonePrefix)
        XCTAssertEqual(dict["phoneNumber"] as? String, phoneNumber)
        XCTAssertEqual(dict["rqdata"] as? String, rqdata)
        XCTAssertEqual(dict["resetOnError"] as? Bool, resetOnError)
        XCTAssertEqual(dict.count, 4)
    }

    func test__toDictionary__withPartialValues() {
        // Given
        let phonePrefix = "44"
        let params = HCaptchaVerifyParams(phonePrefix: phonePrefix)

        // When
        let dict = params.toDictionary()

        // Then
        XCTAssertEqual(dict["phonePrefix"] as? String, phonePrefix)
        XCTAssertNil(dict["phoneNumber"])
        XCTAssertEqual(dict["resetOnError"] as? Bool, true)
        XCTAssertEqual(dict.count, 2)
    }

    func test__toDictionary__withNilValues() {
        // Given
        let params = HCaptchaVerifyParams()

        // When
        let dict = params.toDictionary()

        // Then
        XCTAssertNil(dict["phonePrefix"])
        XCTAssertNil(dict["phoneNumber"])
        XCTAssertEqual(dict["resetOnError"] as? Bool, true)
        XCTAssertEqual(dict.count, 1)
    }

    func test__toDictionary__withOnlyPhoneNumber() {
        // Given
        let phoneNumber = "+1234567890"
        let resetOnError = false
        let params = HCaptchaVerifyParams(phoneNumber: phoneNumber, resetOnError: resetOnError)

        // When
        let dict = params.toDictionary()

        // Then
        XCTAssertNil(dict["phonePrefix"])
        XCTAssertEqual(dict["phoneNumber"] as? String, phoneNumber)
        XCTAssertEqual(dict["resetOnError"] as? Bool, resetOnError)
        XCTAssertEqual(dict.count, 2)
    }

    func test__toDictionary__withOnlyRqdata() {
        // Given
        let rqdata = "test-rqdata-string"
        let resetOnError = false
        let params = HCaptchaVerifyParams(rqdata: rqdata, resetOnError: resetOnError)

        // When
        let dict = params.toDictionary()

        // Then
        XCTAssertNil(dict["phonePrefix"])
        XCTAssertNil(dict["phoneNumber"])
        XCTAssertEqual(dict["rqdata"] as? String, rqdata)
        XCTAssertEqual(dict["resetOnError"] as? Bool, resetOnError)
        XCTAssertEqual(dict.count, 2)
    }

    // MARK: - toJSONString Tests

    func test__toJSONString__validJSON() {
        // Given
        let phonePrefix = "44"
        let phoneNumber = "1234567890"
        let rqdata = "test-rqdata"
        let resetOnError = false
        let params = HCaptchaVerifyParams(phonePrefix: phonePrefix,
                                         phoneNumber: phoneNumber,
                                         rqdata: rqdata,
                                         resetOnError: resetOnError)

        // When
        let jsonString = params.toJSONString()

        // Then
        XCTAssertNotNil(jsonString)

        // Verify JSON structure
        guard let data = jsonString?.data(using: .utf8) else {
            XCTFail("Failed to convert to data")
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON")
            return
        }
        XCTAssertEqual(json["phonePrefix"] as? String, phonePrefix)
        XCTAssertEqual(json["phoneNumber"] as? String, phoneNumber)
        XCTAssertEqual(json["rqdata"] as? String, rqdata)
        XCTAssertEqual(json["resetOnError"] as? Bool, resetOnError)
    }

    func test__toJSONString__withNilValues() {
        // Given
        let params = HCaptchaVerifyParams()

        // When
        let jsonString = params.toJSONString()

        // Then
        XCTAssertNotNil(jsonString)

        // Verify JSON structure
        guard let data = jsonString?.data(using: .utf8) else {
            XCTFail("Failed to convert to data")
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON")
            return
        }
        XCTAssertNil(json["phonePrefix"])
        XCTAssertNil(json["phoneNumber"])
        XCTAssertEqual(json["resetOnError"] as? Bool, true)
    }

    func test__toJSONString__withPartialValues() {
        // Given
        let phonePrefix = "44"
        let params = HCaptchaVerifyParams(phonePrefix: phonePrefix)

        // When
        let jsonString = params.toJSONString()

        // Then
        XCTAssertNotNil(jsonString)

        // Verify JSON structure
        guard let data = jsonString?.data(using: .utf8) else {
            XCTFail("Failed to convert to data")
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON")
            return
        }
        XCTAssertEqual(json["phonePrefix"] as? String, phonePrefix)
        XCTAssertNil(json["phoneNumber"])
        XCTAssertEqual(json["resetOnError"] as? Bool, true)
    }

    // MARK: - Edge Cases

    func test__init__withEmptyStrings() {
        // Given
        let emptyPrefix = ""
        let emptyNumber = ""

        // When
        let params = HCaptchaVerifyParams(phonePrefix: emptyPrefix, phoneNumber: emptyNumber)

        // Then
        XCTAssertEqual(params.phonePrefix, emptyPrefix)
        XCTAssertEqual(params.phoneNumber, emptyNumber)
        XCTAssertTrue(params.resetOnError)
    }

    func test__toDictionary__withEmptyStrings() {
        // Given
        let params = HCaptchaVerifyParams(phonePrefix: "", phoneNumber: "")

        // When
        let dict = params.toDictionary()

        // Then
        XCTAssertEqual(dict["phonePrefix"] as? String, "")
        XCTAssertEqual(dict["phoneNumber"] as? String, "")
        XCTAssertEqual(dict["resetOnError"] as? Bool, true)
    }

    func test__toJSONString__withEmptyStrings() {
        // Given
        let params = HCaptchaVerifyParams(phonePrefix: "", phoneNumber: "")

        // When
        let jsonString = params.toJSONString()

        // Then
        XCTAssertNotNil(jsonString)

        // Verify JSON structure
        guard let data = jsonString?.data(using: .utf8) else {
            XCTFail("Failed to convert to data")
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON")
            return
        }
        XCTAssertEqual(json["phonePrefix"] as? String, "")
        XCTAssertEqual(json["phoneNumber"] as? String, "")
        XCTAssertEqual(json["resetOnError"] as? Bool, true)
    }

    func test__init__withSpecialCharacters() {
        // Given
        let phonePrefix = "+44"
        let phoneNumber = "+1-234-567-8900"

        // When
        let params = HCaptchaVerifyParams(phonePrefix: phonePrefix, phoneNumber: phoneNumber)

        // Then
        XCTAssertEqual(params.phonePrefix, phonePrefix)
        XCTAssertEqual(params.phoneNumber, phoneNumber)
        XCTAssertTrue(params.resetOnError)
    }

    func test__toJSONString__withSpecialCharacters() {
        // Given
        let phonePrefix = "+44"
        let phoneNumber = "+1-234-567-8900"
        let params = HCaptchaVerifyParams(phonePrefix: phonePrefix, phoneNumber: phoneNumber)

        // When
        let jsonString = params.toJSONString()

        // Then
        XCTAssertNotNil(jsonString)

        // Verify JSON structure
        guard let data = jsonString?.data(using: .utf8) else {
            XCTFail("Failed to convert to data")
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON")
            return
        }
        XCTAssertEqual(json["phonePrefix"] as? String, phonePrefix)
        XCTAssertEqual(json["phoneNumber"] as? String, phoneNumber)
        XCTAssertEqual(json["resetOnError"] as? Bool, true)
    }

    // MARK: - Objective-C Compatibility Tests

    func test__objcCompatibility__init() {
        // Given/When
        let params = HCaptchaVerifyParams(phonePrefix: "44", phoneNumber: "1234567890", resetOnError: false)

        // Then
        XCTAssertTrue(params.isKind(of: NSObject.self))
        XCTAssertTrue(params.responds(to: #selector(HCaptchaVerifyParams.toDictionary)))
        XCTAssertTrue(params.responds(to: #selector(HCaptchaVerifyParams.toJSONString)))
    }

    func test__objcCompatibility__properties() {
        // Given
        let params = HCaptchaVerifyParams(phonePrefix: "44", phoneNumber: "1234567890", resetOnError: false)

        // When/Then
        XCTAssertTrue(params.responds(to: #selector(getter: HCaptchaVerifyParams.phonePrefix)))
        XCTAssertTrue(params.responds(to: #selector(getter: HCaptchaVerifyParams.phoneNumber)))
        XCTAssertTrue(params.responds(to: #selector(getter: HCaptchaVerifyParams.resetOnError)))
    }

    // MARK: - Memory Management Tests

    func test__memoryManagement__retainCycle() {
        // Given
        weak var weakParams: HCaptchaVerifyParams?

        // When
        autoreleasepool {
            let params = HCaptchaVerifyParams(phonePrefix: "44", phoneNumber: "1234567890")
            weakParams = params
        }

        // Then
        XCTAssertNil(weakParams, "HCaptchaVerifyParams should not create retain cycles")
    }
}
