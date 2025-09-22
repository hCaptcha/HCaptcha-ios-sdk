//
//  InMemorySink.swift
//  HCaptcha
//
//  Copyright © 2025 HCaptcha. All rights reserved.
//

import Foundation

/// In-memory sink that keeps only the most recent 50 events
public final class InMemorySink {
    private var events: [[String: Any]] = []
    private let maxEvents = 50
    private let queue = DispatchQueue(label: "com.hcaptcha.journey", attributes: .concurrent)

    public init() {}

    public func emit(_ event: [String: Any]) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            // Append new event and drop oldest ones if over capacity
            self.events.append(event)
            if self.events.count > self.maxEvents {
                let overflowCount = self.events.count - self.maxEvents
                self.events.removeFirst(overflowCount)
            }
        }
    }

    /// Drain collected events and clear the buffer
    public func drain() -> [[String: Any]] {
        return queue.sync(flags: .barrier) {
            let eventsToReturn = events
            events.removeAll()
            return eventsToReturn
        }
    }

}

/// Bridge sink that converts JLEvent to JourneyEvent
final class JourneyBridgeSink: JourneyliticsSink {
    private let inMemorySink: InMemorySink

    init(inMemorySink: InMemorySink) {
        self.inMemorySink = inMemorySink
    }

    func emit(_ event: JLEvent) {
        let journeyEvent: [String: Any] = [
            FieldKey.timestamp.rawValue: event.timestampMs,
            FieldKey.kind.rawValue: event.kind.rawValue,
            FieldKey.view.rawValue: event.view,
            FieldKey.meta.rawValue: event.metadata
        ]
        inMemorySink.emit(journeyEvent)
    }
}
