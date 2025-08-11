//
//  FuncAreaModel.swift
//  GrowthSDK
//
//  Created by arvin on 2025/6/15.
//

import Foundation

// MARK: - 功能区域模型
internal struct FunctionArea: Codable {
    /// HTML 标签名
    var tag: String = ""
    /// 区域位置
    var rect: FunctionRect?
    
    init() {}
}

// MARK: - 功能区域位置
internal struct FunctionRect: Codable {
    /// 左边距（网页坐标）
    var left: CGFloat = 0
    /// 顶部边距（网页坐标）
    var top: CGFloat = 0
    /// 右边距（网页坐标）
    var right: CGFloat = 0
    /// 底部边距（网页坐标）
    var bottom: CGFloat = 0
    
    init() {}
    
    /// 获取宽度
    var width: CGFloat {
        return right - left
    }
    
    /// 获取高度
    var height: CGFloat {
        return bottom - top
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
    
    /// 转换为屏幕坐标系的CGRect
    /// - Parameters:
    ///   - webViewFrame: WebView的框架尺寸
    ///   - scrollOffset: WebView的滚动偏移量
    /// - Returns: 屏幕坐标系中的CGRect
    func toScreenRect(in webViewFrame: CGRect, scrollOffset: CGPoint = .zero) -> CGRect {
        let safeAreaInsets = getSafeAreaInsets()
        // getBoundingClientRect() 返回的是相对于视口的坐标
        // 所以 top 和 bottom 已经是相对于当前视口的位置
        // 只需要加上 WebView 在屏幕中的位置即可
        let screenX = webViewFrame.origin.x + left
        let screenY = webViewFrame.origin.y + top //+ safeAreaInsets.top
        
        // 打印调试信息
        //        DispatchQueue.main.async {
        //            print("[H5] [FunctionRect] 🔄 坐标转换:")
        //            print("[H5]   - 原始位置（视口坐标）: (\(left), \(top))")
        //            print("[H5]   - WebView位置: (\(webViewFrame.origin.x), \(webViewFrame.origin.y))")
        //            print("[H5]   - 最终位置（屏幕坐标）: (\(screenX), \(screenY))")
        //        }
        
        return CGRect(x: screenX, y: screenY, width: width, height: height)
    }
    
    /// 转换为屏幕坐标系的中心点
    /// - Parameters:
    ///   - webViewFrame: WebView的框架尺寸
    ///   - scrollOffset: WebView的滚动偏移量
    /// - Returns: 屏幕坐标系中的中心点
    func toScreenCenter(in webViewFrame: CGRect, scrollOffset: CGPoint = .zero) -> CGPoint {
        let screenRect = toScreenRect(in: webViewFrame, scrollOffset: scrollOffset)
        return CGPoint(x: screenRect.midX, y: screenRect.midY)
    }
    
    /// 判断是否在可视区域内
    /// - Parameters:
    ///   - webViewFrame: WebView的框架尺寸
    ///   - scrollOffset: WebView的滚动偏移量
    /// - Returns: 是否在可视区域内
    func isVisibleInScreen(in webViewFrame: CGRect, scrollOffset: CGPoint = .zero) -> Bool {
        let screenRect = toScreenRect(in: webViewFrame, scrollOffset: scrollOffset)
        let safeAreaInsets = getSafeAreaInsets()
        
        // 计算可视区域
        let visibleRect = CGRect(
            x: webViewFrame.origin.x,
            y: webViewFrame.origin.y + safeAreaInsets.top,
            width: webViewFrame.width,
            height: webViewFrame.height - safeAreaInsets.top - safeAreaInsets.bottom
        )
        
        return screenRect.intersects(visibleRect)
    }
}
