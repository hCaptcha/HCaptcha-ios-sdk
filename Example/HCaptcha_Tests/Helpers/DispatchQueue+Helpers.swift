//
//  DispatchQueue+Helpers.swift
//  HCaptcha_Tests
//
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@testable import HCaptcha
import Foundation

extension DispatchQueue {
    private static var workItems = [AnyHashable: DispatchWorkItem]()
    private static var lastDebounceCallTimes = [AnyHashable: DispatchTime]()
    private static let nilContext = UUID()

    func throttle(deadline: DispatchTime, context: AnyHashable = nilContext, action: @escaping () -> Void) {
        let worker = DispatchWorkItem {
            defer { DispatchQueue.workItems.removeValue(forKey: context) }
            action()
        }

        asyncAfter(deadline: deadline, execute: worker)

        DispatchQueue.workItems[context]?.cancel()
        DispatchQueue.workItems[context] = worker
    }

    func debounce(interval: Double, context: AnyHashable = nilContext, action: @escaping () -> Void) {
        let now = DispatchTime.now()
        if let last = DispatchQueue.lastDebounceCallTimes[context], last + interval > now {
            return
        }

        DispatchQueue.lastDebounceCallTimes[context] = now + interval
        async(execute: action)

        throttle(deadline: now + interval) {
            DispatchQueue.lastDebounceCallTimes.removeValue(forKey: context)
        }
    }

    static func resetOnceTokens() {
        defer { objc_sync_exit(self) }
        objc_sync_enter(self)
        onceTokenStorage.removeAll()
    }
}
