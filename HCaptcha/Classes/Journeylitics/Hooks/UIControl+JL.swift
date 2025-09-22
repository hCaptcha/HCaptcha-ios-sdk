import Foundation
#if canImport(UIKit)
import UIKit

private var jlControlSwizzled: Bool = false

extension UIControl {
    static func jl_installHook() {
        guard !jlControlSwizzled else { return }
        jlControlSwizzled = true
        Swizzler.swizzleInstanceMethod(
            self,
            original: #selector(UIControl.sendAction(_:to:for:)),
            swizzled: #selector(UIControl.jl_sendAction(_:to:for:))
        )
    }

    static func jl_uninstallHook() {
        guard jlControlSwizzled else { return }
        jlControlSwizzled = false
        Swizzler.unswizzleInstanceMethod(
            self,
            original: #selector(UIControl.sendAction(_:to:for:)),
            swizzled: #selector(UIControl.jl_sendAction(_:to:for:))
        )
    }

    @objc func jl_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        var meta = createFieldMap((.action, NSStringFromSelector(action)))
        if let typedTarget = target {
            meta[FieldKey.target.jsonKey] = String(describing: type(of: typedTarget as AnyObject))
        }
        JLCore.shared.emit(kind: .click, view: self.viewTypeName, metadata: meta)
        jl_sendAction(action, to: target, for: event)
    }
}
#endif
