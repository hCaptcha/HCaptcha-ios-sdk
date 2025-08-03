import Foundation

enum TestTimeouts {
    private static let isCI: Bool = {
        ProcessInfo.processInfo.environment["CI"] != nil
    }()

    static let standard: TimeInterval = isCI ? 60 : 10
    static let long: TimeInterval = isCI ? 120 : 30
    static let short: TimeInterval = isCI ? 5 : 1
}
