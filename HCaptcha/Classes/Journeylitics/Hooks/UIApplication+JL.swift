import Foundation
#if canImport(UIKit)
import UIKit

private var jlAppSwizzled: Bool = false
private var jlAppActionSwizzled: Bool = false

extension UIApplication {
    static func jl_installHook() {
        guard !jlAppSwizzled else { return }
        jlAppSwizzled = true
        Swizzler.swizzleInstanceMethod(
            self,
            original: #selector(UIApplication.sendEvent(_:)),
            swizzled: #selector(UIApplication.jl_sendEvent(_:))
        )
        if !jlAppActionSwizzled {
            jlAppActionSwizzled = true
            Swizzler.swizzleInstanceMethod(
                self,
                original: #selector(UIApplication.sendAction(_:to:from:for:)),
                swizzled: #selector(UIApplication.jl_sendAction(_:to:from:for:))
            )
        }
    }

    static func jl_uninstallHook() {
        guard jlAppSwizzled else { return }
        jlAppSwizzled = false
        Swizzler.unswizzleInstanceMethod(
            self,
            original: #selector(UIApplication.sendEvent(_:)),
            swizzled: #selector(UIApplication.jl_sendEvent(_:))
        )
        if jlAppActionSwizzled {
            jlAppActionSwizzled = false
            Swizzler.unswizzleInstanceMethod(
                self,
                original: #selector(UIApplication.sendAction(_:to:from:for:)),
                swizzled: #selector(UIApplication.jl_sendAction(_:to:from:for:))
            )
        }
    }

    @objc func jl_sendEvent(_ event: UIEvent) {
        if event.type == .touches, let touches = event.allTouches {
            // Report only ended taps and primary info to keep it light
            let ended = touches.filter { $0.phase == .ended }
            if let touch = ended.first, let view = touch.view {
                let location = touch.location(in: view)
                let meta = createFieldMap(
                    (.x, Double(location.x)),
                    (.y, Double(location.y)),
                    (.taps, touch.tapCount)
                )
                JLCore.shared.emit(kind: .click, view: view.viewTypeName, metadata: meta)
            }
        }
        jl_sendEvent(event)
    }

    @objc func jl_sendAction(_ action: Selector, to target: Any?, from sender: Any?, for event: UIEvent?) -> Bool {
        if let barButton = sender as? UIBarButtonItem {
            var meta = createFieldMap((.action, NSStringFromSelector(action)))
            if let typedTarget = target {
                meta[FieldKey.target.jsonKey] = String(describing: type(of: typedTarget as AnyObject))
            }
            JLCore.shared.emit(kind: .click, view: barButton.viewTypeName, metadata: meta)
        }
        return jl_sendAction(action, to: target, from: sender, for: event)
    }
}
#endif
