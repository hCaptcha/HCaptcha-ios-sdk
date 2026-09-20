//
//  HCaptchaMessagePresenter.swift
//  HCaptcha
//
//  Copyright © 2026 HCaptcha. All rights reserved.
//

import Foundation
import MessageUI
import UIKit

/// Abstraction over presenting and dismissing the native SMS composer.
internal protocol HCaptchaMessagePresenter: AnyObject {
    /// Presents the SMS composer configured with the provided recipient and body.
    /// - returns: `false` when the composer could not be shown, so the caller can fall back
    ///            to opening the external Messages app.
    func present(recipient: String?, body: String?, from sourceView: UIView,
                 delegate: MFMessageComposeViewControllerDelegate) -> Bool

    /// Dismisses the currently presented composer, if any.
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

internal enum HCaptchaMessagePresenterFactory {
    /// The composer cannot send anything on the simulator, so a stub stands in for it there.
    static func make() -> HCaptchaMessagePresenter {
#if targetEnvironment(simulator)
        return HCaptchaSimulatorMessagePresenter()
#else
        return HCaptchaSystemMessagePresenter()
#endif
    }
}

/// Default implementation backed by `MFMessageComposeViewController`.
internal final class HCaptchaSystemMessagePresenter: NSObject, HCaptchaMessagePresenter {
    private typealias Log = HCaptchaLogger

    private weak var presentedController: MFMessageComposeViewController?

    func present(recipient: String?, body: String?, from sourceView: UIView,
                 delegate: MFMessageComposeViewControllerDelegate) -> Bool {
        guard MFMessageComposeViewController.canSendText() else {
            Log.debug("MessagePresenter: device cannot send texts")
            return false
        }

        guard let presenter = HCaptchaPresentationTarget.viewController(for: sourceView) else {
            return false
        }

        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = delegate

        if let recipient = recipient, !recipient.isEmpty {
            controller.recipients = [recipient]
        }

        controller.body = body

        // The recipient and body are left out of the log on purpose: the body carries the
        // one-time verification code.
        Log.debug("MessagePresenter: presenting composer, recipient: " +
                  "\(recipient == nil ? "missing" : "set") body: \(body == nil ? "missing" : "set")")

        presenter.present(controller, animated: true)
        presentedController = controller

        return true
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let controller = presentedController else {
            completion?()
            return
        }

        presentedController = nil
        controller.dismiss(animated: animated, completion: completion)
    }
}

#if targetEnvironment(simulator)
/// Simulator stand-in for `MFMessageComposeViewController`, which reports `canSendText() == false`
/// there and would otherwise silently drop the whole flow.
///
/// It shows what the composer would have been pre-filled with and drives the same
/// `didFinishWith` path, so the dismissal and return-to-challenge behavior stays testable
/// without a physical device. Compiled into simulator slices only.
internal final class HCaptchaSimulatorMessagePresenter: NSObject, HCaptchaMessagePresenter {
    private typealias Log = HCaptchaLogger

    private weak var presentedAlert: UIAlertController?

    func present(recipient: String?, body: String?, from sourceView: UIView,
                 delegate: MFMessageComposeViewControllerDelegate) -> Bool {
        Log.warn("MessagePresenter: simulator stub, no SMS is sent. " +
                 "To: \(recipient ?? "none") Body: \(body ?? "none")")

        guard let presenter = HCaptchaPresentationTarget.viewController(for: sourceView) else {
            return false
        }

        let alert = UIAlertController(
            title: "SMS Composer (Simulator)",
            message: """
            To: \(recipient ?? "—")

            \(body ?? "—")

            The real composer is shown on a device; nothing is sent here.
            """,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self, weak delegate] _ in
            self?.finish(.cancelled, delegate: delegate)
        })
        alert.addAction(UIAlertAction(title: "Send", style: .default) { [weak self, weak delegate] _ in
            self?.finish(.sent, delegate: delegate)
        })

        presenter.present(alert, animated: true)
        presentedAlert = alert

        return true
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let alert = presentedAlert else {
            completion?()
            return
        }

        presentedAlert = nil
        alert.dismiss(animated: animated, completion: completion)
    }

    /// `UIAlertController` dismisses itself when an action fires, so the alert is dropped
    /// before the delegate runs and the follow-up `dismiss` becomes a no-op.
    private func finish(_ result: MessageComposeResult, delegate: MFMessageComposeViewControllerDelegate?) {
        presentedAlert = nil
        delegate?.messageComposeViewController(MFMessageComposeViewController(), didFinishWith: result)
    }
}
#endif

// MARK: - Presentation target

/// Resolves the view controller the composer should be presented from.
internal enum HCaptchaPresentationTarget {
    private typealias Log = HCaptchaLogger

    static func viewController(for view: UIView) -> UIViewController? {
        guard let owner = owningViewController(of: view) else {
            Log.warn("MessagePresenter: view is not attached to a view controller")
            return nil
        }

        return topmostPresented(from: owner)
    }

    /// The webview is a subview of the host view passed to `validate(on:)`, so the responder
    /// chain lands on the host's own view controller. `rootViewController` only covers the case
    /// of a view that is in a window but not owned by a controller.
    private static func owningViewController(of view: UIView) -> UIViewController? {
        var responder: UIResponder? = view.next

        while let current = responder {
            if let controller = current as? UIViewController {
                return controller
            }
            responder = current.next
        }

        return view.window?.rootViewController
    }

    /// Walks the modal stack. Container controllers are deliberately not unwrapped: presenting
    /// from a `UINavigationController` or `UITabBarController` is valid, and drilling into their
    /// children only risks picking a controller that is not the one presenting modals.
    private static func topmostPresented(from root: UIViewController) -> UIViewController? {
        var candidate = root

        // Stop above a controller that is on its way out: it cannot present, but whatever is
        // presenting it can, once the transition completes.
        while let presented = candidate.presentedViewController, !presented.isBeingDismissed {
            candidate = presented
        }

        // UIKit drops a `present` call made on a controller that is still appearing, which would
        // lose the composer with only a runtime warning. Better to fall back to Messages.
        guard !candidate.isBeingPresented else {
            Log.warn("MessagePresenter: top view controller is mid-transition")
            return nil
        }

        return candidate
    }
}
