import Foundation

@objc(HCaptchaJourneysImpl)
public final class HCaptchaJourneysImpl: NSObject {
    private static var inMemorySink: InMemorySink?
    private static var started: Bool = false

    /// Start Journeylitics via an Obj-C visible entrypoint.
    /// Options are reserved for future configuration and should contain Foundation-only types.
    @objc public static func start(_ options: NSDictionary? = nil) {
        if started { return }
        started = true

        let sink = InMemorySink()
        inMemorySink = sink
        let bridgeSink = JourneyBridgeSink(inMemorySink: sink)

        let config = JourneyliticsConfig(
            sinks: [bridgeSink],
            enableScreens: true,
            enableControls: true,
            enableTouches: true,
            enableGestures: true,
            enableScrolls: true,
            enableLists: true,
            enableTextInputs: true
        )
        JLCore.shared.startIfNeeded(configuration: config)
    }

    /// Stop collecting and detach sinks. Hook un-swizzling is not supported.
    @objc public static func stop() {
        guard started else { return }
        started = false
        inMemorySink = nil
        JLCore.shared.stop()
    }

    /// Drain collected events for transmission to JavaScript. Returns NSArray of NSDictionary.
    @objc public static func drainEvents() -> NSArray {
        guard let events = inMemorySink?.drain() else { return [] }
        return events as NSArray
    }
}
