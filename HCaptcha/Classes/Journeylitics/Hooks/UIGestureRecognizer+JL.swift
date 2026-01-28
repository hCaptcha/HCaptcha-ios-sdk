import Foundation
#if canImport(UIKit)
import UIKit
import ObjectiveC

private var jlGestureSwizzled: Bool = false
private var jlGestureObservedKey: UInt8 = 0

extension UIGestureRecognizer {
    static func jl_installHook() {
        guard !jlGestureSwizzled else { return }
        jlGestureSwizzled = true
        Swizzler.swizzleInstanceMethod(
            self,
            original: #selector(UIGestureRecognizer.addTarget(_:action:)),
            swizzled: #selector(UIGestureRecognizer.jl_addTarget(_:action:))
        )
    }

    static func jl_uninstallHook() {
        guard jlGestureSwizzled else { return }
        jlGestureSwizzled = false
        Swizzler.unswizzleInstanceMethod(
            self,
            original: #selector(UIGestureRecognizer.addTarget(_:action:)),
            swizzled: #selector(UIGestureRecognizer.jl_addTarget(_:action:))
        )
    }

    @objc func jl_addTarget(_ target: Any, action: Selector) {
        jl_addTarget(target, action: action)
        if objc_getAssociatedObject(self, &jlGestureObservedKey) == nil {
            jl_addTarget(JLCore.shared, action: #selector(JLCore.handleGesture(_:)))
            objc_setAssociatedObject(self, &jlGestureObservedKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

}
#endif
