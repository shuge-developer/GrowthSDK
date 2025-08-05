//
//  AdElementModel.swift
//  GameWrapper
//
//  Created by arvin on 2025/6/15.
//

import Foundation
import UIKit

// MARK: - 广告区域模型
internal struct AdArea: Codable {
    /// 左边距（网页坐标）
    var left: CGFloat = 0
    /// 顶部边距（网页坐标）
    var top: CGFloat = 0
    /// 右边距（网页坐标）
    var right: CGFloat = 0
    /// 底部边距（网页坐标）
    var bottom: CGFloat = 0
    /// 宽度
    var width: CGFloat = 0
    /// 高度
    var height: CGFloat = 0
    
    init() {}
    
    /// 创建区域
    /// - Parameters:
    ///   - left: 左边距
    ///   - top: 顶部边距
    ///   - width: 宽度
    ///   - height: 高度
    init(left: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat) {
        self.left = left
        self.top = top
        self.width = width
        self.height = height
        self.right = left + width
        self.bottom = top + height
    }
    
    /// 获取中心点（网页坐标）
    var center: CGPoint {
        return CGPoint(x: left + width/2, y: top + height/2)
    }
    
    /// 判断区域是否有效
    var isValid: Bool {
        return width > 0 && height > 0
    }
    
    /// 转换为CGRect（网页坐标）
    var rect: CGRect {
        return CGRect(x: left, y: top, width: width, height: height)
    }
    
    /// 转换为屏幕坐标系的CGRect，考虑安全区域
    /// - Parameters:
    ///   - webViewFrame: WebView的框架尺寸
    /// - Returns: 屏幕坐标系中的CGRect
    func toScreenRect(in webViewFrame: CGRect) -> CGRect {
        // 计算网页内容在WebView中的实际位置
        let scaledX = left
        let scaledY = top
        let scaledWidth = width
        let scaledHeight = height
        
        // 获取安全区域高度
        let safeAreaTopInset: CGFloat
        
        if #available(iOS 11.0, *) {
            // 使用主窗口的安全区域
            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            safeAreaTopInset = keyWindow?.safeAreaInsets.top ?? 44 // 默认值，iPhone X 以上为 44
        } else {
            // iOS 11 以下，使用状态栏高度
            safeAreaTopInset = UIApplication.shared.statusBarFrame.height
        }
        
        // 计算WebView在屏幕中的位置偏移，考虑安全区域
        let screenX = webViewFrame.origin.x + scaledX
        let screenY = webViewFrame.origin.y + scaledY //+ safeAreaTopInset // 加上顶部安全区高度
        
        // 打印调试信息（异步执行，避免影响视图构建）
        DispatchQueue.main.async {
            print("[H5] [AdArea] 🔄 坐标转换: 原始top=\(top), 安全区顶部=\(safeAreaTopInset), 调整后Y=\(screenY)")
        }
        
        return CGRect(x: screenX, y: screenY, width: scaledWidth, height: scaledHeight)
    }
    
    /// 获取调整后的顶部位置（考虑安全区域）
    /// - Returns: 调整后的顶部位置
    func getAdjustedTop() -> CGFloat {
        // 获取安全区域高度
        let safeAreaTopInset: CGFloat
        
        if #available(iOS 11.0, *) {
            // 使用主窗口的安全区域
            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            safeAreaTopInset = keyWindow?.safeAreaInsets.top ?? 44 // 默认值，iPhone X 以上为 44
        } else {
            // iOS 11 以下，使用状态栏高度
            safeAreaTopInset = UIApplication.shared.statusBarFrame.height
        }
        
        return top + safeAreaTopInset
    }
    
    /// 获取调整后的中心点Y坐标（考虑安全区域）
    /// - Returns: 调整后的中心点Y坐标
    func getAdjustedCenterY() -> CGFloat {
        // 获取安全区域高度
        let safeAreaTopInset: CGFloat
        
        if #available(iOS 11.0, *) {
            // 使用主窗口的安全区域
            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            safeAreaTopInset = keyWindow?.safeAreaInsets.top ?? 44 // 默认值，iPhone X 以上为 44
        } else {
            // iOS 11 以下，使用状态栏高度
            safeAreaTopInset = UIApplication.shared.statusBarFrame.height
        }
        
        return center.y + safeAreaTopInset
    }
    
    /// 转换为屏幕坐标系的中心点，考虑安全区域
    /// - Parameters:
    ///   - webViewFrame: WebView的框架尺寸
    /// - Returns: 屏幕坐标系中的中心点
    func toScreenCenter(in webViewFrame: CGRect) -> CGPoint {
        let screenRect = toScreenRect(in: webViewFrame)
        let centerPoint = CGPoint(x: screenRect.midX, y: screenRect.midY)
        
        // 使用闭包包装打印语句，避免在视图构建过程中执行
        DispatchQueue.main.async {
            print("[H5] [AdArea] 📍 计算广告中心点: \(centerPoint)")
        }
        
        return centerPoint
    }
    
    /// 获取区域内的随机点
    /// - Returns: 在区域内的随机坐标点，如果区域无效则返回nil
    var randomPoint: CGPoint? {
        guard isValid else { return nil }
        let randomX = CGFloat.random(in: left...(left + width))
        let randomY = CGFloat.random(in: top...(top + height))
        let point = CGPoint(x: randomX, y: randomY)
        DispatchQueue.main.async {
            print("[H5] [AdArea] 🎲 生成随机点: \(point), 区域: {\(left), \(top), \(width), \(height)}")
        }
        return point
    }
}

// MARK: - 广告元素状态枚举
internal enum AdLoadStatus: String, Codable {
    case done = "done"
    case loading = "loading"
    case failed = "failed"
    case unknown
    
    var isFinish: Bool {
        switch self {
        case .done, .failed:
            return true
        default:
            return false
        }
    }
}

internal enum AdFillStatus: String, Codable {
    case filled = "filled"
    case unfilled = "unfilled"
    case unknown
    
    var isfilled: Bool {
        if case .filled = self {
            return true
        }
        return false
    }
}

internal enum AdDisplayStatus: String, Codable {
    case displayed = "displayed"
    case visible = "visible"
    case hidden = "hidden"
    case unknown
    
    var isVisible: Bool {
        switch self {
        case .displayed, .visible:
            return true
        default:
            return false
        }
    }
}

// MARK: - 广告元素类型
internal enum AdElementType: String, Codable {
    case iner = "iner"
    case anchor = "anchor"
    case native = "native"
    case banner = "banner"
    case unknown = "default"
}

/// 获取设备安全区域信息
internal func getSafeAreaInsets() -> UIEdgeInsets {
    if #available(iOS 11.0, *) {
        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        return keyWindow?.safeAreaInsets ?? UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
    } else {
        return UIEdgeInsets(top: UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
    }
}

// MARK: - 广告元素模型
internal struct AdElement: Codable {
    /// 广告区域位置和尺寸
    var area: AdArea?
    /// 广告是否可见
    var visible: Bool = false
    /// 广告ID，某些广告平台会提供唯一标识
    var id: String = ""
    /// 广告来源，如 AdScene、AdMob 等
    var source: String = ""
    /// 广告类型，如 banner、native、interstitial 等
    var type: AdElementType = .unknown
    /// 广告加载状态，如 loading、done、failed 等
    var loadStatus: AdLoadStatus = .unknown
    /// 广告填充状态，表示是否成功填充了广告内容
    var fillStatus: AdFillStatus = .unknown
    /// 广告显示状态，如 visible、hidden 等
    var displayStatus: AdDisplayStatus = .unknown
    
    init() {}
    
    /// 判断广告是否可点击
    var isClickable: Bool {
        return visible && area?.isValid == true
    }
    
    /// 获取屏幕坐标系中的广告区域，考虑安全区域
    /// - Parameters:
    ///   - webViewFrame: WebView的框架尺寸
    /// - Returns: 屏幕坐标系中的广告区域，如果area为nil则返回nil
    //    func getScreenRect(in webViewFrame: CGRect) -> CGRect? {
    //        guard let adArea = area else { return nil }
    //
    //        // 获取考虑安全区域的屏幕矩形
    //        let screenRect = adArea.toScreenRect(in: webViewFrame)
    //
    //        //        // 异步打印，避免影响视图构建
    //        //        DispatchQueue.main.async {
    //        //            print("[H5] [AdElement] 📊 广告ID=\(id), 类型=\(type.rawValue), 屏幕矩形=\(screenRect)")
    //        //        }
    //
    //        return screenRect
    //    }
    
    /// 获取屏幕坐标系中的广告中心点，考虑安全区域
    /// - Parameters:
    ///   - webViewFrame: WebView的框架尺寸
    /// - Returns: 屏幕坐标系中的广告中心点，如果area为nil则返回nil
    //    func getScreenCenter(in webViewFrame: CGRect) -> CGPoint? {
    //        guard let adArea = area else { return nil }
    //
    //        // 获取考虑安全区域的屏幕中心点
    //        let centerPoint = adArea.toScreenCenter(in: webViewFrame)
    //
    //        //        // 异步打印，避免影响视图构建
    //        //        DispatchQueue.main.async {
    //        //            print("[H5] [AdElement] 📍 广告ID=\(id), 类型=\(type.rawValue), 屏幕中心点=\(centerPoint)")
    //        //        }
    //
    //        return centerPoint
    //    }
    
    /// 判断广告是否在屏幕可见区域内
    /// - Parameter webViewFrame: WebView的框架尺寸
    /// - Returns: 是否在屏幕可见区域内
    //    func isVisibleOnScreen(in webViewFrame: CGRect) -> Bool {
    //        guard let screenRect = getScreenRect(in: webViewFrame) else { return false }
    //
    //        // 获取安全区域
    //        let safeAreaTopInset: CGFloat
    //        let safeAreaBottomInset: CGFloat
    //
    //        if #available(iOS 11.0, *) {
    //            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    //            safeAreaTopInset = keyWindow?.safeAreaInsets.top ?? 44
    //            safeAreaBottomInset = keyWindow?.safeAreaInsets.bottom ?? 34
    //        } else {
    //            safeAreaTopInset = UIApplication.shared.statusBarFrame.height
    //            safeAreaBottomInset = 0
    //        }
    //
    //        // 计算WebView的可见区域
    //        let visibleRect = CGRect(
    //            x: webViewFrame.origin.x,
    //            y: webViewFrame.origin.y + safeAreaTopInset,
    //            width: webViewFrame.width,
    //            height: webViewFrame.height - safeAreaTopInset - safeAreaBottomInset
    //        )
    //
    //        // 检查广告是否与可见区域相交
    //        let isVisible = screenRect.intersects(visibleRect)
    //
    //        //        // 异步打印，避免影响视图构建
    //        //        DispatchQueue.main.async {
    //        //            print("[H5] [AdElement] 👁️ 广告ID=\(id), 类型=\(type.rawValue), 是否可见=\(isVisible)")
    //        //        }
    //
    //        return isVisible
    //    }
}

// MARK: -
internal struct IframeResult {
    let found: Bool
    let url: URL?
    //let info: [String: Any]?
    
    static func result(from string: Any) -> IframeResult {
        guard let dict =  string as? [String: Any] else {
            let result = IframeResult(found: false, url: nil)
            return result
        }
        let found = (dict["found"] as? Bool) ?? false
        if let urlString = dict["src"] as? String {
            if urlString.hasPrefix("http") {
                let url = URL(string: urlString)
                let result = IframeResult(found: found, url: url)
                return result
            }
        }
        let result = IframeResult(found: found, url: nil)
        return result
    }
}
