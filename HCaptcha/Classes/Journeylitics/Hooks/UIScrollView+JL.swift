import Foundation
#if canImport(UIKit)
import UIKit
import ObjectiveC

private var jlScrollSwizzled: Bool = false
private var jlProxyKey: UInt8 = 0

final class JLScrollDelegateProxy: NSObject, UIScrollViewDelegate {
    weak var original: UIScrollViewDelegate?

    init(original: UIScrollViewDelegate?) {
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

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let meta = createFieldMap((.x, Double(scrollView.contentOffset.x)), (.y, Double(scrollView.contentOffset.y)))
        JLCore.shared.emit(kind: .drag, view: scrollView.viewTypeName, metadata: meta)
        (original as AnyObject?)?.scrollViewWillBeginDragging?(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        (original as AnyObject?)?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        let meta = createFieldMap((.x, Double(scrollView.contentOffset.x)), (.y, Double(scrollView.contentOffset.y)))
        JLCore.shared.emit(kind: .drag, view: scrollView.viewTypeName, metadata: meta)
    }
}

extension UIScrollView {
    static func jl_installHook() {
        guard !jlScrollSwizzled else { return }
        jlScrollSwizzled = true
        Swizzler.swizzleInstanceMethod(
            self,
            original: NSSelectorFromString("setDelegate:"),
            swizzled: #selector(UIScrollView.jl_setDelegate(_:))
        )
        jl_wrapExistingDelegates()
    }

    static func jl_uninstallHook() {
        guard jlScrollSwizzled else { return }
        jlScrollSwizzled = false
        Swizzler.unswizzleInstanceMethod(
            self,
            original: NSSelectorFromString("setDelegate:"),
            swizzled: #selector(UIScrollView.jl_setDelegate(_:))
        )
    }

    @objc func jl_setDelegate(_ delegate: UIScrollViewDelegate?) {
        if let delegateObject = delegate {
            let proxy = JLScrollDelegateProxy(original: delegateObject)
            objc_setAssociatedObject(self, &jlProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            jl_setDelegate(proxy)
        } else {
            jl_setDelegate(nil)
        }
    }

    private static func jl_wrapExistingDelegates() {
        var scrollViews: [UIScrollView] = []
        for window in jl_allWindows() {
            jl_collectScrollViews(in: window, into: &scrollViews)
        }
        for scrollView in scrollViews {
            guard !(scrollView.delegate is JLScrollDelegateProxy) else { continue }
            let proxy = JLScrollDelegateProxy(original: scrollView.delegate)
            objc_setAssociatedObject(scrollView, &jlProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            scrollView.jl_setDelegate(proxy)
        }
    }

    private static func jl_allWindows() -> [UIWindow] {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
        }
        return UIApplication.shared.windows
    }

    private static func jl_collectScrollViews(in view: UIView, into list: inout [UIScrollView]) {
        if let scrollView = view as? UIScrollView {
            list.append(scrollView)
        }
        for subview in view.subviews {
            jl_collectScrollViews(in: subview, into: &list)
        }
    }
}
#endif
