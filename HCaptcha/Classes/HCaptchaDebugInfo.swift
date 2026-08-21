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

private func sampledImages(_ images: [String]) -> [String] {
    let sortedImages = images.sorted()
    guard sortedImages.count > 20 else { return sortedImages }
    return Array(sortedImages.prefix(10)) + Array(sortedImages.suffix(10))
}

private func updateHash(_ ctx: UnsafeMutablePointer<CC_MD5_CTX>, with images: [String]) {
    for imagePath in sampledImages(images) {
        let imageName = URL(fileURLWithPath: imagePath).lastPathComponent
        _ = imageName.withCString { CC_MD5_Update(ctx, $0, CC_LONG(strlen($0))) }
    }
}

private func bundleShortVersion() -> String {
    let sdkBundle = Bundle(for: HCaptchaDebugInfo.self)
    let sdkBundleShortVer = sdkBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    return sdkBundleShortVer?.jsSanitize() ?? "unknown"
}

class HCaptchaDebugInfo {
    static func json(disabled: Bool) -> String {
        return disabled ? "[]" : json
    }

    public static let json: String = HCaptchaDebugInfo.buildDebugInfoJson()

    private class func buildDebugInfoJson() -> String {
        let failsafeJson = "[]"
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(buildDebugInfo()) else { return failsafeJson }
        guard let json = String(data: jsonData, encoding: .utf8) else { return failsafeJson }
        return json
    }

    private class func buildDebugInfo() -> [String] {
        var depsCtx = CC_MD5_CTX()
        var sysCtx = CC_MD5_CTX()
        var appCtx = CC_MD5_CTX()
        CC_MD5_Init(&depsCtx)
        CC_MD5_Init(&sysCtx)
        CC_MD5_Init(&appCtx)

        var depsImages: [String] = []
        var sysImages: [String] = []
        var appImages: [String] = []
        let execPath = Bundle.main.executablePath
        let imageCount = _dyld_image_count()
        for imageIdx in 0..<imageCount {
            guard let imageNamePtr = _dyld_get_image_name(imageIdx) else { continue }
            let imagePath = String(cString: imageNamePtr)

            if imagePath.isSystemFramework {
                sysImages.append(imagePath)
            } else if let execPath = execPath, imagePath.hasPrefix(execPath) {
                appImages.append(imagePath)
            } else {
                depsImages.append(imagePath)
            }
        }

        updateHash(&depsCtx, with: depsImages)
        updateHash(&sysCtx, with: sysImages)
        updateHash(&appCtx, with: appImages)

        let depsHash = getFinalHash(&depsCtx)
        let sysHash = getFinalHash(&sysCtx)
        let appHash = getFinalHash(&appCtx)
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
