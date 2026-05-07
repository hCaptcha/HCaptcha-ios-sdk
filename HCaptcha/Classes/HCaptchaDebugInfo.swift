//
//  HCaptchaDebugInfo.m
//  HCaptcha
//
//  Copyright © 2024 HCaptcha. All rights reserved.
//

import Foundation
import CommonCrypto
import UIKit
import MachO

private extension String {
    func jsSanitize() -> String {
        return self.replacingOccurrences(of: ".", with: "_")
    }

    var isSystemFramework: Bool {
        return self.contains("/System/Library/") || self.contains("/usr/lib/")
    }
}

private func getFinalHash(_ ctx: UnsafeMutablePointer<CC_MD5_CTX>) -> String {
    var digest: [UInt8] = Array(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    CC_MD5_Final(&digest, ctx)
    let hexDigest = digest.map { String(format: "%02hhx", $0) }.joined()
    return hexDigest
}

private func bundleShortVersion() -> String {
    let sdkBundle = Bundle(for: HCaptchaDebugInfo.self)
    let sdkBundleShortVer = sdkBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    return sdkBundleShortVer?.jsSanitize() ?? "unknown"
}

class HCaptchaDebugInfo {
    public static let json: String = HCaptchaDebugInfo.buildDebugInfoJson()

    private class func buildDebugInfoJson() -> String {
        let failsafeJson = "[]"
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(buildDebugInfo()) else { return failsafeJson }
        guard let json = String(data: jsonData, encoding: .utf8) else { return failsafeJson }
        return json
    }

    private class func buildDebugInfo() -> [String] {
        let depsCtx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        let sysCtx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        let appCtx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        CC_MD5_Init(depsCtx)
        CC_MD5_Init(sysCtx)
        CC_MD5_Init(appCtx)

        let imageCount = _dyld_image_count()
        for imageIdx in 0..<imageCount {
            guard let imageNamePtr = _dyld_get_image_name(imageIdx) else { continue }
            let imagePath = String(cString: imageNamePtr)

            var md5Ctx = depsCtx
            if imagePath.isSystemFramework {
                md5Ctx = sysCtx
            } else if let execPath = Bundle.main.executablePath, imagePath.hasPrefix(execPath) {
                md5Ctx = appCtx
            }

            var classCount: UInt32 = 0
            guard let classNames = objc_copyClassNamesForImage(imageNamePtr, &classCount) else { continue }
            defer { free(classNames) }

            for classIdx in 0..<Int(classCount) {
                let className = String(cString: classNames[classIdx])
                CC_MD5_Update(md5Ctx, className, CC_LONG(className.count))
            }
        }

        let depsHash = getFinalHash(depsCtx)
        let sysHash = getFinalHash(sysCtx)
        let appHash = getFinalHash(appCtx)
        let iver = UIDevice.current.systemVersion.jsSanitize()

        return [
            "sys_\(String(describing: sysHash))",
            "deps_\(String(describing: depsHash))",
            "app_\(String(describing: appHash))",
            "iver_\(String(describing: iver))",
            "sdk_\(bundleShortVersion())"
        ]
    }
}
