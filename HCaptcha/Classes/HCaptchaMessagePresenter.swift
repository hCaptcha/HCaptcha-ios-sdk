//
//  HCaptchaMessagePresenter.swift
//  HCaptcha
//
//

import Foundation
import MessageUI
import UIKit

/// Abstraction over presenting and dismissing the native SMS composer.
internal protocol HCaptchaMessagePresenter: AnyObject {
    /// Returns `true` when the device can display the compose view.
    func canSendText() -> Bool

    /// Presents the SMS composer configured with the provided recipient and body.
    @discardableResult
    func present(recipient: String?, body: String?, from sourceView: UIView,
                 delegate: MFMessageComposeViewControllerDelegate) -> Bool

    /// Dismisses the currently presented composer, if any.
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

/// Default implementation backed by `MFMessageComposeViewController`.
internal final class HCaptchaSystemMessagePresenter: NSObject, HCaptchaMessagePresenter {
    private weak var presentedController: MFMessageComposeViewController?

    func canSendText() -> Bool {
        MFMessageComposeViewController.canSendText()
    }

    @discardableResult
    func present(recipient: String?, body: String?, from sourceView: UIView,
                 delegate: MFMessageComposeViewControllerDelegate) -> Bool {
        guard canSendText(),
              let presenter = topPresenter(for: sourceView) else {
            return false
        }

        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = delegate

        if let recipient = recipient, !recipient.isEmpty {
            controller.recipients = [recipient]
        }

        controller.body = body

        presenter.present(controller, animated: true)
        presentedController = controller

        return true
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let controller = presentedController else {
            completion?()
            return
        }

        controller.dismiss(animated: animated, completion: completion)
        presentedController = nil
    }
}

// MARK: - Private helpers

private extension HCaptchaSystemMessagePresenter {
    func topPresenter(for view: UIView) -> UIViewController? {
        var responder: UIResponder? = view

        while let next = responder?.next {
            if let controller = next as? UIViewController {
                return topViewController(from: controller)
            }
            responder = next
        }

        if let controller = view.window?.rootViewController {
            return topViewController(from: controller)
        }

        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
            let windows = scenes.flatMap { $0.windows }
            if let controller = windows.first(where: { $0.isKeyWindow })?.rootViewController {
                return topViewController(from: controller)
            }
        }

        if let controller = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            return topViewController(from: controller)
        }

        return nil
    }

    func topViewController(from root: UIViewController?) -> UIViewController? {
        guard let root = root else { return nil }

        var candidate: UIViewController? = root

        while let presented = candidate?.presentedViewController {
            candidate = presented
        }

        if let navigation = candidate as? UINavigationController {
            return topViewController(from: navigation.visibleViewController ?? navigation.topViewController)
        }

        if let tab = candidate as? UITabBarController {
            return topViewController(from: tab.selectedViewController ?? tab)
        }

        return candidate
    }
}
