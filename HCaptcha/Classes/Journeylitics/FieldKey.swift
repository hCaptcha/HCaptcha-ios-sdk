import Foundation

/**
 * Serialization enum for consistent field mapping across platforms
 * Maps readable field names to short JSON keys for minification
 */
public enum FieldKey: String {
    // Top-level fields (always present)
    case kind = "k"
    case view = "v"
    case timestamp = "ts"
    case meta = "m"

    // Meta fields (nested under meta object)
    case id = "id"
    case screen = "sc"
    case action = "ac"
    case value = "val"
    case x = "x"
    case y = "y"
    case index = "idx"
    case section = "sct"
    case target = "tt"
    case control = "ct"
    case gesture = "gt"
    case state = "gs"
    case taps = "tap"
    case containerView = "cv"
    case length = "ln"
}

extension FieldKey {
    var jsonKey: String { self.rawValue }
}

/**
 * Utility extension to get view type names cleanly
 */
extension NSObject {
    var viewTypeName: String {
        return String(describing: type(of: self))
    }
}

/**
 * Helper function to create meta field mappings (O(1) - no iteration)
 */
public func createMetaMap(_ pairs: (FieldKey, String)...) -> [String: String] {
    var result: [String: String] = [:]
    for (key, value) in pairs {
        result[key.jsonKey] = value
    }
    return result
}

/**
 * Helper function to create field mappings (O(1) - no iteration)
 */
public func createFieldMap(_ pairs: (FieldKey, Any)...) -> [String: Any] {
    var result: [String: Any] = [:]
    for (key, value) in pairs {
        result[key.jsonKey] = value
    }
    return result
}
