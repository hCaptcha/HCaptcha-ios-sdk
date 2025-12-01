import Foundation
#if canImport(UIKit)
import UIKit
import ObjectiveC

private var jlTableSwizzled: Bool = false
private var jlTableProxyKey: UInt8 = 0

final class JLTableDelegateProxy: NSObject, UITableViewDelegate {
    weak var original: UITableViewDelegate?

    init(original: UITableViewDelegate?) {
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let meta = createFieldMap((.index, indexPath.row))
        JLCore.shared.emit(kind: .click, view: tableView.viewTypeName, metadata: meta)
        (original as AnyObject?)?.tableView?(tableView, didSelectRowAt: indexPath)
    }
}

extension UITableView {
    static func jl_installTableHook() {
        guard !jlTableSwizzled else { return }
        jlTableSwizzled = true
        Swizzler.swizzleInstanceMethod(
            self,
            original: NSSelectorFromString("setDelegate:"),
            swizzled: #selector(UITableView.jl_table_setDelegate(_:))
        )
    }

    static func jl_uninstallTableHook() {
        guard jlTableSwizzled else { return }
        jlTableSwizzled = false
        Swizzler.unswizzleInstanceMethod(
            self,
            original: NSSelectorFromString("setDelegate:"),
            swizzled: #selector(UITableView.jl_table_setDelegate(_:))
        )
    }

    @objc func jl_table_setDelegate(_ delegate: UITableViewDelegate?) {
        if let delegateObject = delegate {
            let proxy = JLTableDelegateProxy(original: delegateObject)
            objc_setAssociatedObject(self, &jlTableProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            jl_table_setDelegate(proxy)
        } else {
            jl_table_setDelegate(nil)
        }
    }
}
#endif
