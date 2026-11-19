//
//  HCaptchaSdkData.swift
//  HCaptcha
//
//  Copyright © 2026 HCaptcha. All rights reserved.
//

import Foundation

/// Native device data sent to the challenge as `sdk_data`
internal enum HCaptchaSdkData {
    private static let hardwareModelPattern = "^(iPhone|iPad|iPod)[0-9]{1,3},[0-9]{1,3}$"

    static let json: String = buildJson(machine: currentMachine())

    /// A list, not an object, so the payload carries no key names; index 0 is the hardware model
    static func buildJson(machine: String?) -> String {
        let data: [String] = hardwareModel(from: machine).map { [$0] } ?? []
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let json = String(data: jsonData, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    /// Keeps device identifiers like iPhone18,2, simulators and Macs report an architecture instead
    static func hardwareModel(from machine: String?) -> String? {
        guard let machine = machine,
              machine.range(of: hardwareModelPattern, options: .regularExpression) != nil else {
            return nil
        }
        return machine
    }

    private static func currentMachine() -> String? {
        var systemInfo = utsname()
        guard uname(&systemInfo) == 0 else {
            return nil
        }
        return withUnsafeBytes(of: &systemInfo.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
