import Foundation
#if canImport(UIKit)
import UIKit
import ObjectiveC

private var jlPickerSwizzled: Bool = false
private var jlPickerProxyKey: UInt8 = 0

final class JLPickerDelegateProxy: NSObject, UIPickerViewDelegate {
    weak var original: UIPickerViewDelegate?

    init(original: UIPickerViewDelegate?) {
        self.original = original
        super.init()
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        return (original as AnyObject?)?.responds?(to: aSelector) ?? false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return original
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let meta = createFieldMap((.index, row))
        JLCore.shared.emit(kind: .click, view: pickerView.viewTypeName, metadata: meta)
        (original as AnyObject?)?.pickerView?(pickerView, didSelectRow: row, inComponent: component)
    }
}

extension UIPickerView {
    static func jl_installHook() {
        guard !jlPickerSwizzled else { return }
        jlPickerSwizzled = true
        Swizzler.swizzleInstanceMethod(
            self,
            original: NSSelectorFromString("setDelegate:"),
            swizzled: #selector(UIPickerView.jl_setDelegate(_:))
        )
    }

    static func jl_uninstallHook() {
        guard jlPickerSwizzled else { return }
        jlPickerSwizzled = false
        Swizzler.unswizzleInstanceMethod(
            self,
            original: NSSelectorFromString("setDelegate:"),
            swizzled: #selector(UIPickerView.jl_setDelegate(_:))
        )
    }

    @objc func jl_setDelegate(_ delegate: UIPickerViewDelegate?) {
        if let delegateObject = delegate {
            let proxy = JLPickerDelegateProxy(original: delegateObject)
            objc_setAssociatedObject(self, &jlPickerProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            jl_setDelegate(proxy)
        } else {
            jl_setDelegate(nil)
        }
    }
}
#endif
