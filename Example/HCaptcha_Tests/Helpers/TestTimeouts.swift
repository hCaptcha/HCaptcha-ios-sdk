import Foundation

enum TestTimeouts {
    private static let isCI: Bool = {
        ProcessInfo.processInfo.environment["CI"] != nil
    }()

    static let standard: TimeInterval = isCI ? 30 : 5
    static let long: TimeInterval = isCI ? 60 : 15
    static let short: TimeInterval = isCI ? 10 : 2
}
