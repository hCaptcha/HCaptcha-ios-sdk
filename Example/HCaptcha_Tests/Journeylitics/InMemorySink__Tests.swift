//
//  InMemorySink__Tests.swift
//  HCaptcha_Tests
//
//  Copyright © 2025 HCaptcha. All rights reserved.
//

@testable import HCaptcha
import XCTest

final class InMemorySink__Tests: XCTestCase {
    func test__limit_and_recency() {
        let sink = InMemorySink()
        // Add 60 events with increasing idx
        for i in 0..<60 {
            sink.emit([FieldKey.index.jsonKey: i])
        }
        let drained = sink.drain()
        // Limit to 50, keeping most recent
        XCTAssertEqual(drained.count, 50)
        let idxs = drained.compactMap { $0[FieldKey.index.jsonKey] as? Int }
        XCTAssertEqual(idxs.count, 50)
        XCTAssertEqual(idxs.first, 10)
        XCTAssertEqual(idxs.last, 59)
        // Drain again should be empty
        XCTAssertEqual(sink.drain().count, 0)
    }
}
