import Foundation

public enum JLEventKind: String {
    case screen
    case click
    case drag
    case gesture
    case edit
}

public struct JLEvent {
    public let timestamp: Int64
    public let kind: JLEventKind
    public let view: String
    public let metadata: [String: Any]

    public init(
        timestamp: Int64 = Int64(Date().timeIntervalSince1970),
        kind: JLEventKind,
        view: String,
        metadata: [String: Any] = [:]
    ) {
        self.timestamp = timestamp
        self.kind = kind
        self.view = view
        self.metadata = metadata
    }
}
