import Foundation

// Public entry point for the library. Exposed at the top level
// so apps can simply call Journeylitics.start(...).
public enum Journeylitics {
    public static func start(configuration: JourneyliticsConfig = .default) {
        JLCore.shared.startIfNeeded(configuration: configuration)
    }

    public static func stop() {
        JLCore.shared.stop()
    }
}
