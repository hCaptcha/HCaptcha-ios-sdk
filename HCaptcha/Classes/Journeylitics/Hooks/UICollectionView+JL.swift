import Foundation
#if canImport(UIKit)
import UIKit
import ObjectiveC

private var jlCollectionSwizzled: Bool = false
private var jlCollectionProxyKey: UInt8 = 0

final class JLCollectionDelegateProxy: NSObject, UICollectionViewDelegate {
    weak var original: UICollectionViewDelegate?

    init(original: UICollectionViewDelegate?) {
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let meta = createFieldMap((.section, indexPath.section), (.index, indexPath.item))
        JLCore.shared.emit(kind: .click, view: collectionView.viewTypeName, metadata: meta)
        (original as AnyObject?)?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }
}

extension UICollectionView {
    static func jl_installCollectionHook() {
        guard !jlCollectionSwizzled else { return }
        jlCollectionSwizzled = true
        Swizzler.swizzleInstanceMethod(
            self,
            original: NSSelectorFromString("setDelegate:"),
            swizzled: #selector(UICollectionView.jl_collection_setDelegate(_:))
        )
    }

    static func jl_uninstallCollectionHook() {
        guard jlCollectionSwizzled else { return }
        jlCollectionSwizzled = false
        Swizzler.unswizzleInstanceMethod(
            self,
            original: NSSelectorFromString("setDelegate:"),
            swizzled: #selector(UICollectionView.jl_collection_setDelegate(_:))
        )
    }

    @objc func jl_collection_setDelegate(_ delegate: UICollectionViewDelegate?) {
        if let delegateObject = delegate {
            let proxy = JLCollectionDelegateProxy(original: delegateObject)
            objc_setAssociatedObject(self, &jlCollectionProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            jl_collection_setDelegate(proxy)
        } else {
            jl_collection_setDelegate(nil)
        }
    }
}
#endif
