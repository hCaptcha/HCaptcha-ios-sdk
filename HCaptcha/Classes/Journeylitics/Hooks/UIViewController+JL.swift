import Foundation
#if canImport(UIKit)
import UIKit

private var jlVcSwizzled: Bool = false

extension UIViewController {
    static func jl_installHook() {
        guard !jlVcSwizzled else { return }
        jlVcSwizzled = true
        Swizzler.swizzleInstanceMethod(
            self,
            original: #selector(UIViewController.viewDidAppear(_:)),
            swizzled: #selector(UIViewController.jl_viewDidAppear(_:))
        )
        Swizzler.swizzleInstanceMethod(
            self,
            original: #selector(UIViewController.viewDidDisappear(_:)),
            swizzled: #selector(UIViewController.jl_viewDidDisappear(_:))
        )
    }

    static func jl_uninstallHook() {
        guard jlVcSwizzled else { return }
        jlVcSwizzled = false
        Swizzler.unswizzleInstanceMethod(
            self,
            original: #selector(UIViewController.viewDidAppear(_:)),
            swizzled: #selector(UIViewController.jl_viewDidAppear(_:))
        )
        Swizzler.unswizzleInstanceMethod(
            self,
            original: #selector(UIViewController.viewDidDisappear(_:)),
            swizzled: #selector(UIViewController.jl_viewDidDisappear(_:))
        )
    }

    @objc func jl_viewDidAppear(_ animated: Bool) {
        jl_viewDidAppear(animated)
        let name = String(describing: type(of: self))
        JLCore.shared.emit(
            kind: .screen,
            view: "UIViewController",
            metadata: createFieldMap((.screen, name), (.action, "appear"))
        )
    }

    @objc func jl_viewDidDisappear(_ animated: Bool) {
        jl_viewDidDisappear(animated)
        let name = String(describing: type(of: self))
        JLCore.shared.emit(
            kind: .screen,
            view: "UIViewController",
            metadata: createFieldMap((.screen, name), (.action, "disappear"))
        )
    }
}
#endif
