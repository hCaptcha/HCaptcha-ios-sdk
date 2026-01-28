import Foundation
#if canImport(UIKit)
import UIKit
import ObjectiveC
#endif

final class JLCore: NSObject {
    static let shared = JLCore()

    private(set) var configuration: JourneyliticsConfig = .default
    private var started: Bool = false

    private override init() {}

    func startIfNeeded(configuration: JourneyliticsConfig) {
        if started { return }
        self.configuration = configuration
        started = true
        #if canImport(UIKit)
        installHooks()
        #endif
    }

    func stop() {
        guard started else { return }
        started = false
        #if canImport(UIKit)
        uninstallHooks()
        #endif
        // Drop all sinks so no events are forwarded after stop
        configuration.sinks = []
    }

    // No ObjC bridge here; the bridge is defined in Core facade

    func emit(kind: JLEventKind, view: String, metadata: [String: Any]) {
        let event = JLEvent(kind: kind, view: view, metadata: metadata)
        for sink in configuration.sinks {
            sink.emit(event)
        }
    }
}

#if canImport(UIKit)
extension JLCore {
    private func installHooks() {
        if configuration.enableScreens {
            UIViewController.jl_installHook()
        }
        if configuration.enableTouches {
            UIApplication.jl_installHook()
        }
        if configuration.enableControls {
            UIControl.jl_installHook()
        }
        if configuration.enableScrolls {
            UIScrollView.jl_installHook()
        }
        if configuration.enableGestures {
            UIGestureRecognizer.jl_installHook()
        }
        if configuration.enableLists {
            UITableView.jl_installTableHook()
            UICollectionView.jl_installCollectionHook()
            UIPickerView.jl_installHook()
        }
        if configuration.enableTextInputs {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleTextFieldDidChange(_:)),
                name: UITextField.textDidChangeNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleTextViewDidChange(_:)),
                name: UITextView.textDidChangeNotification,
                object: nil
            )
            UISearchBar.jl_installHook()
        }
    }

    private func uninstallHooks() {
        if configuration.enableScreens {
            UIViewController.jl_uninstallHook()
        }
        if configuration.enableTouches {
            UIApplication.jl_uninstallHook()
        }
        if configuration.enableControls {
            UIControl.jl_uninstallHook()
        }
        if configuration.enableScrolls {
            UIScrollView.jl_uninstallHook()
        }
        if configuration.enableGestures {
            UIGestureRecognizer.jl_uninstallHook()
        }
        if configuration.enableLists {
            UITableView.jl_uninstallTableHook()
            UICollectionView.jl_uninstallCollectionHook()
            UIPickerView.jl_uninstallHook()
        }
        if configuration.enableTextInputs {
            NotificationCenter.default.removeObserver(self, name: UITextField.textDidChangeNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
            UISearchBar.jl_uninstallHook()
        }
    }

    @objc func handleGesture(_ recognizer: UIGestureRecognizer) {
        let state: String
        switch recognizer.state {
        case .possible: state = "possible"
        case .began: state = "began"
        case .changed: state = "changed"
        case .ended: state = "ended"
        case .cancelled: state = "cancelled"
        case .failed: state = "failed"
        @unknown default: state = "unknown"
        }
        let gestureType = String(describing: type(of: recognizer))
        var meta = createFieldMap(
            (.gesture, gestureType),
            (.state, state)
        )
        if let view = recognizer.view {
            meta[FieldKey.containerView.jsonKey] = String(describing: type(of: view))
        }
        emit(kind: .gesture, view: gestureType, metadata: meta)
    }

    @objc func handleTextFieldDidChange(_ notification: Notification) {
        guard let field = notification.object as? UITextField else { return }
        let meta = createFieldMap(
            (.length, field.text?.count ?? 0)
        )
        emit(kind: .edit, view: String(describing: type(of: field)), metadata: meta)
    }

    @objc func handleTextViewDidChange(_ notification: Notification) {
        guard let textView = notification.object as? UITextView else { return }
        let meta = createFieldMap(
            (.length, textView.text.count)
        )
        emit(kind: .edit, view: String(describing: type(of: textView)), metadata: meta)
    }
}
#endif
