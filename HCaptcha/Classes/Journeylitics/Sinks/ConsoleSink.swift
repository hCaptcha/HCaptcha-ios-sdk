import Foundation

public protocol JourneyliticsSink: AnyObject {
    func emit(_ event: JLEvent)
}

public final class NSLogSink: JourneyliticsSink {
    public init() {}

    public func emit(_ event: JLEvent) {
        let parts: [String: String] = [
            FieldKey.kind.jsonKey: event.kind.rawValue,
            FieldKey.timestamp.jsonKey: String(event.timestampMs),
            FieldKey.meta.jsonKey: event.metadata.description
        ]
        let body = parts.map { (key: String, value: String) in "\"\(key)\":\"\(value)\"" }.joined(separator: ",")
        print("{\(body)}")
    }
}
