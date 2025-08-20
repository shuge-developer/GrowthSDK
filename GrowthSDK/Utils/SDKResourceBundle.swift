//
//  SDKResourceBundle.swift
//  GrowthSDK
//
//  Created by AI Assistant on 2025/08/10.
//

import Foundation

/// 用于定位 SDK 的资源 Bundle。
/// 支持 CocoaPods 和直接集成两种场景
internal enum SDKResourceBundle {
    
    static let bundle: Bundle = {
        // 使用本文件的类型作为定位锚点，避免直接依赖 GrowthKit 类型
        final class BundleToken {}
        let frameworkBundle = Bundle(for: BundleToken.self)
        // 1) 优先查找主包中的资源 bundle（CocoaPods 会把资源 bundle 拷贝到主包）
        if let url = Bundle.main.url(forResource: "GrowthSDKResources", withExtension: "bundle"),
           let res = Bundle(url: url) {
            return res
        }
        // 2) 回退查找框架内部的资源 bundle（手动集成时可能内嵌）
        if let url = frameworkBundle.url(forResource: "GrowthSDKResources", withExtension: "bundle"),
           let res = Bundle(url: url) {
            return res
        }
        // 3) 直接集成场景：直接使用框架自身 bundle，资源文件在框架根目录
        return frameworkBundle
    }()
    
}
