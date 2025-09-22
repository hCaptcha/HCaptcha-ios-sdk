import Foundation
#if canImport(UIKit)
import UIKit
import ObjectiveC

private var jlSearchSwizzled: Bool = false
private var jlSearchProxyKey: UInt8 = 0

final class JLSearchBarDelegateProxy: NSObject, UISearchBarDelegate {
    weak var original: UISearchBarDelegate?
    private var lastLength: Int = 0

    init(original: UISearchBarDelegate?) {
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

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let delta = searchText.count - lastLength
        lastLength = searchText.count
        let meta = createFieldMap((.value, String(delta)))
        JLCore.shared.emit(kind: .click, view: searchBar.viewTypeName, metadata: meta)
        (original as AnyObject?)?.searchBar?(searchBar, textDidChange: searchText)
    }
}

extension UISearchBar {
    static func jl_installHook() {
        guard !jlSearchSwizzled else { return }
        jlSearchSwizzled = true
        Swizzler.swizzleInstanceMethod(
            self,
            original: NSSelectorFromString("setDelegate:"),
            swizzled: #selector(UISearchBar.jl_setDelegate(_:))
        )
    }

    static func jl_uninstallHook() {
        guard jlSearchSwizzled else { return }
        jlSearchSwizzled = false
        Swizzler.unswizzleInstanceMethod(
            self,
            original: NSSelectorFromString("setDelegate:"),
            swizzled: #selector(UISearchBar.jl_setDelegate(_:))
        )
    }

    @objc func jl_setDelegate(_ delegate: UISearchBarDelegate?) {
        if let delegateObject = delegate {
            let proxy = JLSearchBarDelegateProxy(original: delegateObject)
            objc_setAssociatedObject(self, &jlSearchProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            jl_setDelegate(proxy)
        } else {
            jl_setDelegate(nil)
        }
    }
}
#endif
