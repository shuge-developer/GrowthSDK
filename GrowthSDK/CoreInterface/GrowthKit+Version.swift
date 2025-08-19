//
//  GrowthKit+Version.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/10.
//

import Foundation

// MARK: -
public extension GrowthKit {
    @objc static var sdkVersion: String {
        return resolvedSDKVersion
    }
}

// MARK: -
private extension GrowthKit {
    static let resolvedSDKVersion: String = {
        let bundle = Bundle(for: GrowthKit.self)
        if let short = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, !short.isEmpty {
            return short
        }
        if let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String, !build.isEmpty {
            return build
        }
        return "0.0.0"
    }()
}
