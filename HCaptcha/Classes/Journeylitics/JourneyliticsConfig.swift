import Foundation

public struct JourneyliticsConfig {
    public var sinks: [any JourneyliticsSink]
    public var enableScreens: Bool
    public var enableControls: Bool
    public var enableTouches: Bool
    public var enableGestures: Bool
    public var enableScrolls: Bool
    public var enableLists: Bool
    public var enableTextInputs: Bool

    public init(
        sinks: [any JourneyliticsSink] = [NSLogSink()],
        enableScreens: Bool = true,
        enableControls: Bool = true,
        enableTouches: Bool = true,
        enableGestures: Bool = true,
        enableScrolls: Bool = true,
        enableLists: Bool = true,
        enableTextInputs: Bool = true
    ) {
        self.sinks = sinks
        self.enableScreens = enableScreens
        self.enableControls = enableControls
        self.enableTouches = enableTouches
        self.enableGestures = enableGestures
        self.enableScrolls = enableScrolls
        self.enableLists = enableLists
        self.enableTextInputs = enableTextInputs
    }

    public static var `default`: JourneyliticsConfig { JourneyliticsConfig() }
}
