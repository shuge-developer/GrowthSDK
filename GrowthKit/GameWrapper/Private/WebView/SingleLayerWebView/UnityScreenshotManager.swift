//
//  UnityScreenshotManager.swift
//  GrowthKit
//
//  Created by arvin on 2025/1/27.
//

import Foundation
import UIKit

/// Unity截图管理器 - 专门处理Unity视图的截图功能
internal class UnityScreenshotManager {
    
    // MARK: - 单例
    static let shared = UnityScreenshotManager()
    
    // MARK: - 私有属性
    private var unityController: UIViewController?
    private var isCapturingScreenshot: Bool = false
    
    // MARK: - 初始化
    private init() {
        print("[Unity截图] 🎮 Unity截图管理器初始化")
    }
    
    // MARK: - 公共方法
    
    /// 设置Unity控制器
    /// - Parameter controller: Unity控制器
    func setUnityController(_ controller: UIViewController) {
        unityController = controller
        print("[Unity截图] ✅ Unity控制器已设置")
    }
    
    /// 异步获取Unity截图
    /// - Returns: Unity截图，失败时返回nil
    @MainActor
    func captureUnityScreenshot() async -> UIImage? {
        // 防止重复截图
        guard !isCapturingScreenshot else {
            print("[Unity截图] ⚠️ 正在截图中，跳过重复请求")
            return nil
        }
        
        guard let unityController = unityController else {
            print("[Unity截图] ⚠️ Unity控制器未设置，无法截图")
            return nil
        }
        
        guard let unityView = unityController.view else {
            print("[Unity截图] ⚠️ Unity控制器的视图为空，无法截图")
            return nil
        }
        
        guard unityView.bounds.width > 0 && unityView.bounds.height > 0 else {
            print("[Unity截图] ⚠️ Unity视图尺寸无效，无法截图: \(unityView.bounds)")
            return nil
        }
        
        // 检查应用状态
        let applicationState = UIApplication.shared.applicationState
        guard applicationState == .active else {
            print("[Unity截图] ⚠️ 应用状态异常，跳过截图: \(applicationState.rawValue)")
            return nil
        }
        
        // 标记开始截图
        isCapturingScreenshot = true
        defer { isCapturingScreenshot = false }
        
        print("[Unity截图] 📸 开始Unity截图，时间戳: \(Date().timeIntervalSince1970)")
        print("[Unity截图] 📊 Unity视图详情: bounds=\(unityView.bounds), frame=\(unityView.frame)")
        print("[Unity截图] 📊 Unity视图层级: superview=\(unityView.superview != nil ? "存在" : "无"), window=\(unityView.window != nil ? "存在" : "无")")
        print("[Unity截图] 📊 Unity视图可见性: isHidden=\(unityView.isHidden), alpha=\(unityView.alpha)")
        
        
        
        // 检查视图可见性
        guard !unityView.isHidden && unityView.alpha > 0 else {
            print("[Unity截图] ⚠️ Unity视图不可见，无法截图")
            return nil
        }
        
        // 尝试多种截图方法
        if let screenshot = await captureUsingDrawHierarchy(view: unityView) {
            print("[Unity截图] ✅ 使用drawHierarchy方法截图成功")
            return screenshot
        }
        
        print("[Unity截图] 🔄 drawHierarchy方法失败，回退到layer.render方法")
        if let screenshot = await captureUsingLayerRender(view: unityView) {
            print("[Unity截图] ✅ 使用layer.render方法截图成功")
            return screenshot
        }
        
        print("[Unity截图] ❌ 所有截图方法都失败，无法获取Unity截图")
        return nil
    }
    
    // MARK: - 私有方法
    
    
    
    /// 使用drawHierarchy方法截图
    @MainActor
    private func captureUsingDrawHierarchy(view: UIView) async -> UIImage? {
        print("[Unity截图] 📸 使用UIGraphicsImageRenderer进行截图")
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        
        let screenshot = renderer.image { [weak view] ctx in
            guard let view = view else { return }
            
            // 首先尝试afterScreenUpdates: true
            print("[Unity截图] 📸 尝试使用drawHierarchy(afterScreenUpdates: true)")
            var success = view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            
            // 如果失败，回退到afterScreenUpdates: false
            if !success {
                print("[Unity截图] 🔄 afterScreenUpdates: true失败，回退到afterScreenUpdates: false")
                success = view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
            }
            
            if !success {
                print("[Unity截图] ❌ drawHierarchy方法失败")
            }
        }
        
        // 验证截图内容是否有效
        if validateScreenshotContent(screenshot) {
            return screenshot
        }
        
        print("[Unity截图] ⚠️ drawHierarchy截图内容验证失败")
        return nil
    }
    
    /// 使用layer.render方法截图
    @MainActor
    private func captureUsingLayerRender(view: UIView) async -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            print("[Unity截图] ❌ 无法创建图形上下文")
            return nil
        }
        
        // 渲染Unity视图到上下文
        view.layer.render(in: context)
        
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        
        // 验证截图内容是否有效
        if let image = screenshot, validateScreenshotContent(image) {
            return image
        }
        
        print("[Unity截图] ⚠️ layer.render截图内容验证失败")
        return nil
    }
    
    /// 验证截图内容是否有效（不是完全透明或空白）
    @MainActor
    private func validateScreenshotContent(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else {
            print("[Unity截图] ⚠️ 截图CGImage为空")
            return false
        }
        
        // 检查图像尺寸
        let width = cgImage.width
        let height = cgImage.height
        
        guard width > 0 && height > 0 else {
            print("[Unity截图] ⚠️ 截图尺寸无效: \(width)x\(height)")
            return false
        }
        
        print("[Unity截图] 📊 截图尺寸: \(width)x\(height)")
        
        // 采样检查图像是否完全透明
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        
        // 创建一个小的采样区域来检查
        let sampleWidth = min(10, width)
        let sampleHeight = min(10, height)
        let sampleSize = sampleWidth * sampleHeight * bytesPerPixel
        
        var pixelData = [UInt8](repeating: 0, count: sampleSize)
        
        guard let context = CGContext(
            data: &pixelData,
            width: sampleWidth,
            height: sampleHeight,
            bitsPerComponent: 8,
            bytesPerRow: sampleWidth * bytesPerPixel,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("[Unity截图] ⚠️ 无法创建采样上下文，跳过内容验证")
            return true // 如果无法验证，假设有效
        }
        
        // 绘制图像的一小部分到采样上下文
        let sampleRect = CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight)
        let sourceRect = CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight)
        
        if let croppedImage = cgImage.cropping(to: sourceRect) {
            context.draw(croppedImage, in: sampleRect)
        } else {
            print("[Unity截图] ⚠️ 无法裁剪图像进行采样，跳过内容验证")
            return true
        }
        
        // 检查采样像素是否都是透明的
        var nonTransparentPixels = 0
        for i in stride(from: 3, to: sampleSize, by: bytesPerPixel) { // 每4个字节中的第4个是alpha通道
            if pixelData[i] > 10 { // alpha > 10 认为不是完全透明
                nonTransparentPixels += 1
            }
        }
        
        let totalSamplePixels = sampleWidth * sampleHeight
        let transparencyRatio = Double(totalSamplePixels - nonTransparentPixels) / Double(totalSamplePixels)
        
        print("[Unity截图] 📊 截图透明度分析: 透明像素比例=\(String(format: "%.2f", transparencyRatio * 100))%")
        
        // 如果超过95%的像素都是透明的，认为截图无效
        if transparencyRatio > 0.95 {
            print("[Unity截图] ⚠️ 截图内容过于透明，可能无效")
            return false
        }
        
        print("[Unity截图] ✅ 截图内容验证通过")
        return true
    }
}
