//
//  HCaptchaDebugInfo.m
//  HCaptcha
//
//  Copyright © 2022 HCaptcha. All rights reserved.
//

import Foundation
import CommonCrypto
import ObjectiveC.runtime
import UIKit

extension String {
    func jsSanitize() -> String {
        return self.replacingOccurrences(of: ".", with: "_")
    }
}

class HCaptchaDebugInfo {

    private(set) public var json: String!

    init() {
        self.json = self.buildDebugInfoJson()
    }

    private func buildDebugInfoJson() -> String {
        let failsafeJson = "[]"
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(buildDebugInfo()) else { return failsafeJson }
        guard let json = String(data: jsonData, encoding: .utf8) else { return failsafeJson }
        return json
    }

    private func buildDebugInfo() -> [String] {
        let depsCtx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        let sysCtx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        let appCtx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        CC_MD5_Init(depsCtx)
        CC_MD5_Init(sysCtx)
        CC_MD5_Init(appCtx)

        for framework in Bundle.allFrameworks {
            let frameworkPath = URL(string: framework.bundlePath)!
            let frameworkBin = frameworkPath.deletingPathExtension().lastPathComponent
            let image = frameworkPath.appendingPathComponent(frameworkBin).absoluteString
            let systemFramework = image.contains("/Library/PrivateFrameworks/") ||
                                  image.contains("/System/Library/Frameworks/")

            let md5Ctx = systemFramework ? sysCtx : depsCtx
            self.updateInfoFor(image, md5Ctx)
        }

        if let executablePath = Bundle.main.executablePath {
            self.updateInfoFor(executablePath, appCtx)
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

    private func updateInfoFor(_ image: String, _ ctx: UnsafeMutablePointer<CC_MD5_CTX>) {
        var count: UInt32 = 0
        if let imagePtr = (image as NSString).utf8String {
            let classes = objc_copyClassNamesForImage(imagePtr, &count)
            for cls in UnsafeBufferPointer<UnsafePointer<CChar>>(start: classes, count: Int(count)) {
                CC_MD5_Update(ctx, cls, CC_LONG(strlen(cls)))
            }
            classes?.deallocate()
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
}
