//
//  MultiLayerWebContainer.swift
// GameWrapper
//
//  Created by arvin on 2025/6/11.
//

import SwiftUI
import WebKit

// MARK: - WebView层级数据模型
internal struct WebViewLayer: Identifiable, Equatable {
    /// web 视图层级 id
    let id: String
    /// 当前 web 视图的任务
    let task: LinkTask
    /// 当前 web 视图的链接
    let url: String
    /// 层级索引，值越大越在上层
    let zIndex: Int
    /// 透明度
    var opacity: Double = 1.0
    
    static func == (lhs: WebViewLayer, rhs: WebViewLayer) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 多层WebView容器（层级0）
/// 处理多层WebView的展示逻辑
/// 任务类型：展示、滑动、功能点击、滑动+功能点击
internal struct MultiLayerWebContainer: View {
    @ObservedObject private var taskRepository = TaskRepository.shared
    @ObservedObject private var startManager = H5TaskStartManager.shared
    @StateObject private var viewModel = MultiLayerViewModel.shared
    
    // 将 viewModel 作为环境对象传递给子视图
    private var content: some View {
        ZStack {
            ForEach(showActiveLayers) { layer in
                AnimatedWebViewLayer(layer: layer)
                    .zIndex(Double(layer.zIndex))
            }
        }
        .opacity(startManager.multiLayerOpacity)
        .environmentObject(viewModel)
    }
    
    private var showActiveLayers: [WebViewLayer] {
        /// 按zIndex排序显示多层WebView，zIndex小的在底层
        return viewModel.activeLayers.sorted {
            $0.zIndex < $1.zIndex
        }
    }
    
    var body: some View {
        content
            .onAppear {
                print("[H5] [MultiLayerContainer] 🎬 多层WebView容器出现，开始层级展示")
                viewModel.startLayeredDisplay()
            }
            .onDisappear {
                print("[H5] [MultiLayerContainer] 👋 多层WebView容器消失，停止所有展示")
                viewModel.stopAllDisplays()
            }
    }
}

// MARK: - 带动画的WebView层级视图
private struct AnimatedWebViewLayer: View {
    let layer: WebViewLayer
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.95
    @State private var showDebugOverlay: Bool = false
    @State private var hasReportedAds: Bool = false
    @State private var debugRects: [CGRect] = []
    
    @ObservedObject private var startManager = H5TaskStartManager.shared
    @EnvironmentObject private var viewModel: MultiLayerViewModel
    
    var body: some View {
        ZStack {
            GameWebView(layer.url)
                .onLoadFinish { coordinator in
                    print("[H5] [MultiLayerContainer] ✅ WebView加载完成 (zIndex: \(layer.zIndex))")
                    print("[H5] [MultiLayerContainer] 🔗 链接: \(layer.task.link ?? "无链接")")
                    print("[H5] [MultiLayerContainer] 🌐 设置 coordinator")
                    if let handler = viewModel.getTaskHandler(for: layer.id) {
                        handler.setCoordinator(coordinator)
                    }
                    if !hasReportedAds {
                        print("[H5] [Upload] h5 加载上报: \(hasReportedAds)")
                        let json = H5UploadParam.refreshParams(layer.url)
                        NetworkServer.uploadH5Params(json)
                        hasReportedAds = true
                    }
                }
                .onLoadFail { error in
                    print("[H5] [MultiLayerContainer] ❌ WebView加载失败 (zIndex: \(layer.zIndex))")
                    print("[H5] [MultiLayerContainer] 🔗 链接: \(layer.task.link ?? "无链接")")
                    print("[H5] [MultiLayerContainer] 💥 错误: \(error)")
                }
                .opacity(startManager.getLayerOpacity(layer.id))
            
#if DEBUG
            // 调试覆盖层
            if showDebugOverlay {
                //                GeometryReader { geometry in
                //                    ForEach(debugRects.indices, id: \.self) { index in
                //                        let rect = debugRects[index]
                //                        Rectangle()
                //                            .stroke(Color.random, lineWidth: 2)
                //                            .frame(width: rect.width, height: rect.height)
                //                            .position(x: rect.midX, y: rect.midY)
                //                    }
                //                }
                //                .allowsHitTesting(false)
            }
#endif
        }
        .onAppear {
            print("[H5] [MultiLayerContainer] 🎭 层级出现 (zIndex: \(layer.zIndex))")
            print("[H5] [MultiLayerContainer] 📋 任务: \(layer.task.taskDescription)")
            print("[H5] [MultiLayerContainer] 🚀 立即启动任务处理器，开始计时")
            
            // 获取任务处理器并启动，同时设置调试回调
            if let handler = viewModel.getTaskHandler(for: layer.id) {
                handler.start()
                
                handler.onDebugRectsUpdate = { rects in
                    print("[H5] [MultiLayerContainer] 🍀 rects: \(rects)")
                    
                    // 清空之前的可视化区域
                    debugRects = []
                    showDebugOverlay = false
                    
                    // 如果有新的区域，立即显示
                    if !rects.isEmpty {
                        // 使用主线程更新 UI
                        DispatchQueue.main.async {
                            debugRects = rects
                            showDebugOverlay = true
                        }
                    }
                }
            } else {
                print("[H5] [MultiLayerContainer] ❌ 未找到任务处理器: \(layer.id)")
            }
        }
        .onDisappear {
            print("[H5] [Upload] 📌 重置 H5 加载上报标记！！！")
            hasReportedAds = false
        }
    }
}
