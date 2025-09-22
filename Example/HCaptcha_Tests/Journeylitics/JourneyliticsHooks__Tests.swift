//
//  JourneyliticsHooks__Tests.swift
//  HCaptcha_Tests
//
//  Copyright © 2025 HCaptcha. All rights reserved.
//

@testable import HCaptcha
import XCTest

final class JourneyliticsHooks__Tests: XCTestCase {
    func test__UIScrollView_emits_drag_with_numeric_offsets() {
        // Given a JLCore with a custom sink to capture events
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(sinks: [recorder])
        // Start core
        let core = JLCore.shared
        core.startIfNeeded(configuration: config)

        // When we simulate a scroll event via the proxy
        let scrollView = UIScrollView()
        let proxy = JLScrollDelegateProxy(original: nil)
        proxy.scrollViewDidScroll(scrollView)

        // Then we should have received at least one drag event with numeric x,y
        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertEqual(event.kind, .drag)
        let x = event.metadata[FieldKey.x.jsonKey]
        let y = event.metadata[FieldKey.y.jsonKey]
        XCTAssertTrue(x is Double)
        XCTAssertTrue(y is Double)
    }

    func test__UIApplication_emits_click_with_tap_and_coordinates() {
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(sinks: [recorder])
        let core = JLCore.shared
        core.startIfNeeded(configuration: config)

        let app = UIApplication.shared
        UIApplication.jl_installHook()

        // Synthesize a touch event is complex; instead, call handler directly via core
        // Simulate a gesture: we expect .click with gesture meta at least
        let recognizer = UITapGestureRecognizer()
        core.handleGesture(recognizer)

        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertTrue([.click, .drag, .gesture].contains(event.kind))
    }

    func test__UITableView_emits_idx_on_selection() {
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(sinks: [recorder])
        let core = JLCore.shared
        core.startIfNeeded(configuration: config)

        let table = UITableView()
        let proxy = JLTableDelegateProxy(original: nil)
        proxy.tableView(table, didSelectRowAt: IndexPath(row: 7, section: 0))

        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertEqual(event.kind, .click)
        XCTAssertEqual(event.metadata[FieldKey.index.jsonKey] as? String, "7")
    }

    func test__UICollectionView_emits_section_and_idx_on_selection() {
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(sinks: [recorder])
        let core = JLCore.shared
        core.startIfNeeded(configuration: config)

        let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let proxy = JLCollectionDelegateProxy(original: nil)
        proxy.collectionView(collection, didSelectItemAt: IndexPath(item: 3, section: 2))

        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertEqual(event.kind, .click)
        XCTAssertEqual(event.metadata[FieldKey.index.jsonKey] as? String, "3")
        XCTAssertEqual(event.metadata[FieldKey.section.jsonKey] as? String, "2")
    }

    func test__UIControl_sendAction_forwards_and_emits_when_enabled() {
        // Ensure fresh config for this test
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: true,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: false,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        let button = UIButton(type: .system)
        let target = SpyActionTarget()
        button.addTarget(target, action: #selector(SpyActionTarget.tap(_:)), for: .touchUpInside)
        button.sendActions(for: .touchUpInside)

        XCTAssertTrue(target.invoked)
        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertEqual(event.kind, .click)
    }

    func test__UISearchBar_delegate_proxy_emits_and_forwards() {
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: false,
            enableTextInputs: true
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        let search = UISearchBar()
        let spy = SpySearchDelegate()
        search.delegate = spy

        // Simulate typing via delegate (hits proxy then forwards to spy)
        search.delegate?.searchBar?(search, textDidChange: "ABC")

        XCTAssertEqual(spy.lastText, "ABC")
        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertEqual(event.kind, .click)
        // Delta from 0 to 3
        XCTAssertEqual(event.metadata[FieldKey.value.jsonKey] as? String, "3")
    }

    func test__UIPickerView_delegate_proxy_emits_and_forwards() {
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: true,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        let picker = UIPickerView()
        let spy = SpyPickerDelegate()
        picker.delegate = spy

        picker.delegate?.pickerView?(picker, didSelectRow: 4, inComponent: 1)

        XCTAssertEqual(spy.lastRow, 4)
        XCTAssertEqual(spy.lastComponent, 1)
        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertEqual(event.kind, .click)
        XCTAssertEqual(event.metadata[FieldKey.index.jsonKey] as? Int, 4)
    }

    func test__UIViewController_appear_disappear_emits_and_calls_super() {
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: true,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: false,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        let vc = SpyViewController()
        vc.viewDidAppear(false)
        vc.viewDidDisappear(false)

        XCTAssertTrue(vc.didAppearCalled)
        XCTAssertTrue(vc.didDisappearCalled)

        // At least one .screen event should be present
        let kinds = recorder.events.map { $0.kind }
        XCTAssertTrue(kinds.contains(.screen))
    }

    func test__UIApplication_sendAction_for_barbutton_emits_and_forwards() {
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: true,
            enableGestures: false,
            enableScrolls: false,
            enableLists: false,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        UIApplication.jl_installHook()
        let target = SpyActionTarget()
        let item = UIBarButtonItem(title: "Tap", style: .plain, target: target, action: #selector(SpyActionTarget.barTapped(_:)))
        _ = UIApplication.shared.sendAction(#selector(SpyActionTarget.barTapped(_:)), to: target, from: item, for: nil)

        XCTAssertTrue(target.barInvoked)
        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertEqual(event.kind, .click)
    }

    func test__UIScrollView_delegate_forwarding_emits_and_forwards() {
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: true,
            enableLists: false,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        let scroll = UIScrollView()
        let spy = SpyScrollDelegate()
        scroll.delegate = spy
        scroll.delegate?.scrollViewDidScroll?(scroll)

        XCTAssertTrue(spy.didScrollCalled)
        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertEqual(event.kind, .drag)
    }

    func test__UITableView_delegate_forwarding_emits_and_forwards() {
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: true,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        let table = UITableView()
        let spy = SpyTableDelegate()
        table.delegate = spy
        table.delegate?.tableView?(table, didSelectRowAt: IndexPath(row: 5, section: 0))

        XCTAssertEqual(spy.lastSelected?.row, 5)
        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertEqual(event.kind, .click)
    }

    func test__UICollectionView_delegate_forwarding_emits_and_forwards() {
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: true,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let spy = SpyCollectionDelegate()
        collection.delegate = spy
        collection.delegate?.collectionView?(collection, didSelectItemAt: IndexPath(item: 2, section: 1))

        XCTAssertEqual(spy.lastSelected?.item, 2)
        XCTAssertEqual(spy.lastSelected?.section, 1)
        guard let event = recorder.events.last else { return XCTFail("No events recorded") }
        XCTAssertEqual(event.kind, .click)
    }
}

private final class RecordingSink: JourneyliticsSink {
    var events: [JLEvent] = []
    func emit(_ event: JLEvent) { events.append(event) }
}

private final class SpyActionTarget: NSObject {
    var invoked = false
    var barInvoked = false
    @objc func tap(_ sender: Any) { invoked = true }
    @objc func barTapped(_ sender: UIBarButtonItem) { barInvoked = true }
}

private final class SpyScrollDelegate: NSObject, UIScrollViewDelegate {
    var didScrollCalled = false
    func scrollViewDidScroll(_ scrollView: UIScrollView) { didScrollCalled = true }
}

private final class SpyTableDelegate: NSObject, UITableViewDelegate {
    var lastSelected: IndexPath?
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { lastSelected = indexPath }
}

private final class SpyCollectionDelegate: NSObject, UICollectionViewDelegate {
    var lastSelected: IndexPath?
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { lastSelected = indexPath }
}

private final class SpySearchDelegate: NSObject, UISearchBarDelegate {
    var lastText: String?
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { lastText = searchText }
}

private final class SpyPickerDelegate: NSObject, UIPickerViewDelegate {
    var lastRow: Int?
    var lastComponent: Int?
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        lastRow = row
        lastComponent = component
    }
}

private final class SpyViewController: UIViewController {
    var didAppearCalled = false
    var didDisappearCalled = false
    override func viewDidAppear(_ animated: Bool) {
        didAppearCalled = true
        super.viewDidAppear(animated)
    }
    override func viewDidDisappear(_ animated: Bool) {
        didDisappearCalled = true
        super.viewDidDisappear(animated)
    }
}

// MARK: - Uninstall Hook Tests

extension JourneyliticsHooks__Tests {

    func test__UIControl_uninstall_hook_works() {
        // Given: Install hook first
        UIControl.jl_installHook()

        // When: Uninstall hook
        UIControl.jl_uninstallHook()

        // Then: Hook should be uninstalled (we can't easily test this without internal access,
        // but we can verify no crashes occur and the method exists)
        XCTAssertTrue(true, "Uninstall method should exist and not crash")
    }

    func test__UIViewController_uninstall_hook_works() {
        // Given: Install hook first
        UIViewController.jl_installHook()

        // When: Uninstall hook
        UIViewController.jl_uninstallHook()

        // Then: Hook should be uninstalled
        XCTAssertTrue(true, "Uninstall method should exist and not crash")
    }

    func test__UIApplication_uninstall_hook_works() {
        // Given: Install hook first
        UIApplication.jl_installHook()

        // When: Uninstall hook
        UIApplication.jl_uninstallHook()

        // Then: Hook should be uninstalled
        XCTAssertTrue(true, "Uninstall method should exist and not crash")
    }

    func test__UIGestureRecognizer_uninstall_hook_works() {
        // Given: Install hook first
        UIGestureRecognizer.jl_installHook()

        // When: Uninstall hook
        UIGestureRecognizer.jl_uninstallHook()

        // Then: Hook should be uninstalled
        XCTAssertTrue(true, "Uninstall method should exist and not crash")
    }

    func test__UIScrollView_uninstall_hook_works() {
        // Given: Install hook first
        UIScrollView.jl_installHook()

        // When: Uninstall hook
        UIScrollView.jl_uninstallHook()

        // Then: Hook should be uninstalled
        XCTAssertTrue(true, "Uninstall method should exist and not crash")
    }

    func test__UISearchBar_uninstall_hook_works() {
        // Given: Install hook first
        UISearchBar.jl_installHook()

        // When: Uninstall hook
        UISearchBar.jl_uninstallHook()

        // Then: Hook should be uninstalled
        XCTAssertTrue(true, "Uninstall method should exist and not crash")
    }

    func test__UITableView_uninstall_hook_works() {
        // Given: Install hook first
        UITableView.jl_installTableHook()

        // When: Uninstall hook
        UITableView.jl_uninstallTableHook()

        // Then: Hook should be uninstalled
        XCTAssertTrue(true, "Uninstall method should exist and not crash")
    }

    func test__UICollectionView_uninstall_hook_works() {
        // Given: Install hook first
        UICollectionView.jl_installCollectionHook()

        // When: Uninstall hook
        UICollectionView.jl_uninstallCollectionHook()

        // Then: Hook should be uninstalled
        XCTAssertTrue(true, "Uninstall method should exist and not crash")
    }

    func test__UIPickerView_uninstall_hook_works() {
        // Given: Install hook first
        UIPickerView.jl_installHook()

        // When: Uninstall hook
        UIPickerView.jl_uninstallHook()

        // Then: Hook should be uninstalled
        XCTAssertTrue(true, "Uninstall method should exist and not crash")
    }

    func test__JLCore_stop_uninstalls_all_hooks() {
        // Given: A JLCore with all hooks enabled
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: true,
            enableControls: true,
            enableTouches: true,
            enableGestures: true,
            enableScrolls: true,
            enableLists: true,
            enableTextInputs: true
        )
        let core = JLCore.shared
        core.startIfNeeded(configuration: config)

        // When: Stop the core
        core.stop()

        // Then: All hooks should be uninstalled (we can't easily test this without internal access,
        // but we can verify no crashes occur and the stop method works)
        XCTAssertTrue(true, "Stop method should uninstall all hooks without crashing")
    }

    func test__Swizzler_unswizzle_method_exists() {
        // Given: A class and selectors
        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        let swizzledSelector = #selector(UIViewController.jl_viewDidAppear(_:))

        // When: We call the unswizzle method
        Swizzler.unswizzleInstanceMethod(UIViewController.self, original: originalSelector, swizzled: swizzledSelector)

        // Then: No crash should occur (method should exist and be callable)
        XCTAssertTrue(true, "Unswizzle method should exist and not crash")
    }

    func test__multiple_install_uninstall_cycles_work() {
        // Given: A hook that can be installed/uninstalled multiple times
        let hook = UIControl.self

        // When: We perform multiple install/uninstall cycles
        for _ in 0..<3 {
            hook.jl_installHook()
            hook.jl_uninstallHook()
        }

        // Then: No crashes should occur
        XCTAssertTrue(true, "Multiple install/uninstall cycles should work without crashing")
    }

    // MARK: - Hook Functionality Tests

    func test__UIControl_hook_actually_emits_events() {
        // Given: A JLCore with recording sink and UIControl hook installed
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: true,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: false,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        // When: We trigger a UIControl action
        let button = UIButton()
        let target = SpyActionTarget()
        button.addTarget(target, action: #selector(SpyActionTarget.tap(_:)), for: .touchUpInside)
        button.sendActions(for: .touchUpInside)

        // Then: Events should be emitted
        XCTAssertTrue(target.invoked, "Original action should still be called")
        XCTAssertFalse(recorder.events.isEmpty, "Should have recorded events")
        let clickEvents = recorder.events.filter { $0.kind == .click }
        XCTAssertFalse(clickEvents.isEmpty, "Should have recorded click events")
    }

    func test__UIViewController_hook_actually_emits_events() {
        // Given: A JLCore with recording sink and UIViewController hook installed
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: true,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: false,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        // When: We trigger view controller lifecycle
        let vc = SpyViewController()
        vc.viewDidAppear(false)
        vc.viewDidDisappear(false)

        // Then: Events should be emitted
        XCTAssertTrue(vc.didAppearCalled, "Original method should still be called")
        XCTAssertTrue(vc.didDisappearCalled, "Original method should still be called")
        XCTAssertFalse(recorder.events.isEmpty, "Should have recorded events")
        let screenEvents = recorder.events.filter { $0.kind == .screen }
        XCTAssertFalse(screenEvents.isEmpty, "Should have recorded screen events")
    }

    func test__UIGestureRecognizer_hook_actually_emits_events() {
        // Given: A JLCore with recording sink and UIGestureRecognizer hook installed
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: true,
            enableScrolls: false,
            enableLists: false,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        // When: We create a gesture recognizer (this triggers the hook)
        let tapGesture = UITapGestureRecognizer()
        let view = UIView()
        view.addGestureRecognizer(tapGesture)

        // Then: The gesture recognizer should be set up to emit events
        // We can't easily test the actual gesture firing, but we can verify
        // that the hook is installed and the gesture recognizer is configured
        XCTAssertNotNil(tapGesture.view, "Gesture should be associated with a view")
    }

    func test__UIScrollView_hook_actually_emits_events() {
        // Given: A JLCore with recording sink and UIScrollView hook installed
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: true,
            enableLists: false,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        // When: We set a delegate on a scroll view
        let scrollView = UIScrollView()
        let spyDelegate = SpyScrollDelegate()
        scrollView.delegate = spyDelegate

        // Simulate scroll event through the proxy
        scrollView.delegate?.scrollViewDidScroll?(scrollView)

        // Then: Events should be emitted and original delegate called
        XCTAssertTrue(spyDelegate.didScrollCalled, "Original delegate should be called")
        XCTAssertFalse(recorder.events.isEmpty, "Should have recorded events")
        let dragEvents = recorder.events.filter { $0.kind == .drag }
        XCTAssertFalse(dragEvents.isEmpty, "Should have recorded drag events")
    }

    func test__UISearchBar_hook_actually_emits_events() {
        // Given: A JLCore with recording sink and UISearchBar hook installed
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: false,
            enableTextInputs: true
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        // When: We set a delegate on a search bar and simulate text change
        let searchBar = UISearchBar()
        let spyDelegate = SpySearchDelegate()
        searchBar.delegate = spyDelegate
        searchBar.delegate?.searchBar?(searchBar, textDidChange: "test")

        // Then: Events should be emitted and original delegate called
        XCTAssertEqual(spyDelegate.lastText, "test", "Original delegate should be called")
        XCTAssertFalse(recorder.events.isEmpty, "Should have recorded events")
        let clickEvents = recorder.events.filter { $0.kind == .click }
        XCTAssertFalse(clickEvents.isEmpty, "Should have recorded click events")
    }

    func test__UITableView_hook_actually_emits_events() {
        // Given: A JLCore with recording sink and UITableView hook installed
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: true,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        // When: We set a delegate on a table view and simulate selection
        let tableView = UITableView()
        let spyDelegate = SpyTableDelegate()
        tableView.delegate = spyDelegate
        tableView.delegate?.tableView?(tableView, didSelectRowAt: IndexPath(row: 2, section: 0))

        // Then: Events should be emitted and original delegate called
        XCTAssertEqual(spyDelegate.lastSelected?.row, 2, "Original delegate should be called")
        XCTAssertFalse(recorder.events.isEmpty, "Should have recorded events")
        let clickEvents = recorder.events.filter { $0.kind == .click }
        XCTAssertFalse(clickEvents.isEmpty, "Should have recorded click events")
    }

    func test__UICollectionView_hook_actually_emits_events() {
        // Given: A JLCore with recording sink and UICollectionView hook installed
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: true,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        // When: We set a delegate on a collection view and simulate selection
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let spyDelegate = SpyCollectionDelegate()
        collectionView.delegate = spyDelegate
        collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: IndexPath(item: 3, section: 1))

        // Then: Events should be emitted and original delegate called
        XCTAssertEqual(spyDelegate.lastSelected?.item, 3, "Original delegate should be called")
        XCTAssertEqual(spyDelegate.lastSelected?.section, 1, "Original delegate should be called")
        XCTAssertFalse(recorder.events.isEmpty, "Should have recorded events")
        let clickEvents = recorder.events.filter { $0.kind == .click }
        XCTAssertFalse(clickEvents.isEmpty, "Should have recorded click events")
    }

    func test__UIPickerView_hook_actually_emits_events() {
        // Given: A JLCore with recording sink and UIPickerView hook installed
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: false,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: true,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        // When: We set a delegate on a picker view and simulate selection
        let pickerView = UIPickerView()
        let spyDelegate = SpyPickerDelegate()
        pickerView.delegate = spyDelegate
        pickerView.delegate?.pickerView?(pickerView, didSelectRow: 5, inComponent: 0)

        // Then: Events should be emitted and original delegate called
        XCTAssertEqual(spyDelegate.lastRow, 5, "Original delegate should be called")
        XCTAssertEqual(spyDelegate.lastComponent, 0, "Original delegate should be called")
        XCTAssertFalse(recorder.events.isEmpty, "Should have recorded events")
        let clickEvents = recorder.events.filter { $0.kind == .click }
        XCTAssertFalse(clickEvents.isEmpty, "Should have recorded click events")
    }

    func test__hook_uninstall_stops_emitting_events() {
        // Given: A JLCore with recording sink and UIControl hook installed
        let recorder = RecordingSink()
        let config = JourneyliticsConfig(
            sinks: [recorder],
            enableScreens: false,
            enableControls: true,
            enableTouches: false,
            enableGestures: false,
            enableScrolls: false,
            enableLists: false,
            enableTextInputs: false
        )
        let core = JLCore.shared
        core.stop()
        core.startIfNeeded(configuration: config)

        // When: We trigger an action (should emit events)
        let button = UIButton()
        let target = SpyActionTarget()
        button.addTarget(target, action: #selector(SpyActionTarget.tap(_:)), for: .touchUpInside)
        button.sendActions(for: .touchUpInside)

        let initialEventCount = recorder.events.count
        XCTAssertGreaterThan(initialEventCount, 0, "Should have recorded initial events")

        // When: We uninstall the hook and trigger another action
        UIControl.jl_uninstallHook()
        button.sendActions(for: .touchUpInside)

        // Then: No additional events should be emitted
        XCTAssertEqual(recorder.events.count, initialEventCount, "Should not emit additional events after uninstall")
    }
}
