import Foundation

/// Facade that hides runtime lookups and exposes a simple API.
public enum HCaptchaJourneys {
    /// Returns true if a Journeylitics implementation is linked in the app.
    public static var isAvailable: Bool { NSClassFromString("HCaptchaJourneysImpl") != nil }

    /// Starts Journeylitics if available. Returns false when not linked.
    @discardableResult
    public static func start(options: [String: Any]? = nil) -> Bool {
        guard let impl = NSClassFromString("HCaptchaJourneysImpl") else { return false }
        let sel = NSSelectorFromString("start:")
        let dict = options as NSDictionary?
        _ = (impl as AnyObject).perform(sel, with: dict)
        return true
    }

    /// Stops Journeylitics if available. Safe to call multiple times.
    public static func stop() {
        guard let impl = NSClassFromString("HCaptchaJourneysImpl") else { return }
        let sel = NSSelectorFromString("stop")
        _ = (impl as AnyObject).perform(sel)
    }

    /// Returns collected events as raw data ([] when unavailable/empty).
    public static func drainEvents() -> [Any] {
        guard let impl = NSClassFromString("HCaptchaJourneysImpl") else { return [] }
        let sel = NSSelectorFromString("drainEvents")
        guard let unmanaged = (impl as AnyObject).perform(sel),
              let anyObj = unmanaged.takeUnretainedValue() as? [Any],
              JSONSerialization.isValidJSONObject(anyObj) else {
            return []
        }
        return anyObj
    }

    /// Returns collected events as a JSON string ("[]" when unavailable/empty).
    /// @deprecated Use drainEvents() instead for better performance
    public static func drainEventsAsJSONString() -> String {
        let events = drainEvents()
        guard let data = try? JSONSerialization.data(withJSONObject: events, options: []),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}
