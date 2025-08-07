//
//  HumanScrollSimulator.swift
//  GrowthKit
//
//  Created by arvin on 2025/6/15.
//

import UIKit

// MARK: -
/// 人类滑动模拟器
/// 提供模拟人类自然滑动行为的功能
internal final class HumanScrollSimulator {
    
    // 静态实例容器，用于保持模拟器实例直到滚动完成
    private static var activeSimulators = [UUID: HumanScrollSimulator]()
    
    // MARK: - 配置常量
    private enum Config {
        /// 短页面的高度阈值（相对于屏幕高度的倍数）
        static let shortPageThreshold: CGFloat = 1.5
        
        /// 单次滑动的最小距离（像素）
        static let minScrollDistance: CGFloat = 50
        
        /// 单次滑动的最大距离（像素）
        static let maxScrollDistance: CGFloat = 300
        
        /// 短页面单次滑动的最大距离（像素）
        static let shortPageMaxScrollDistance: CGFloat = 100
        
        /// 滑动到底部后反向滑动的概率
        static let reverseScrollProbability: CGFloat = 0.7
        
        /// 反向滑动的距离比例（相对于已滑动距离）
        static let reverseScrollRatio: CGFloat = 0.3
        
        /// 滑动停顿的最小时间（秒）
        static let minPauseDuration: TimeInterval = 0.5
        
        /// 滑动停顿的最大时间（秒）
        static let maxPauseDuration: TimeInterval = 2.0
        
        /// 快速滑动的概率
        static let fastScrollProbability: CGFloat = 0.3
        
        /// 快速滑动的速度倍数（减少持续时间）
        static let fastScrollSpeedMultiplier: CGFloat = 0.6
        
        /// 快速滑动的距离倍数（增加滑动距离）
        static let fastScrollDistanceMultiplier: CGFloat = 1.5
        
        /// 长页面最小滑动段数
        static let longPageMinScrolls: Int = 2
        
        /// 短页面最小滑动段数
        static let shortPageMinScrolls: Int = 1
    }
    
    // MARK: - 公共接口
    /// 模拟人类自然滚动行为（速度先快后慢）
    /// - Parameters:
    ///   - scrollView: 要滚动的 UIScrollView
    ///   - distance: 滚动距离（正值向下滚动，负值向上滚动）
    ///   - duration: 滚动持续时间，默认2秒
    ///   - completion: 滚动完成后的回调
    static func simulateScroll(
        on scrollView: UIScrollView,
        distance: CGFloat,
        duration: TimeInterval = 2.0,
        completion: (() -> Void)? = nil
    ) {
        print("[H5] [HumanScroll] 📌 准备滚动: distance=\(distance), contentSize=\(scrollView.contentSize), contentOffset=\(scrollView.contentOffset)")
        
        let simulator = HumanScrollSimulator(scrollView: scrollView)
        
        // 将模拟器添加到活跃实例容器中
        activeSimulators[simulator.id] = simulator
        
        simulator.startScrolling(
            distance: distance,
            duration: duration,
            completion: {
                // 在完成回调中移除模拟器实例
                activeSimulators.removeValue(forKey: simulator.id)
                print("[H5] [HumanScroll] 🧹 完成后移除模拟器: \(simulator.id), 剩余活跃模拟器: \(activeSimulators.count)")
                completion?()
            }
        )
    }
    
    /// 模拟人类自然滚动行为（速度先快后慢），使用指定的缓动函数
    /// - Parameters:
    ///   - scrollView: 要滚动的 UIScrollView
    ///   - distance: 滚动距离（正值向下滚动，负值向上滚动）
    ///   - duration: 滚动持续时间
    ///   - easingFunction: 缓动函数，接收 0-1 之间的进度值，返回调整后的进度值
    ///   - completion: 滚动完成后的回调
    static func simulateScroll(
        on scrollView: UIScrollView,
        distance: CGFloat,
        duration: TimeInterval = 2.0,
        easingFunction: @escaping (CGFloat) -> CGFloat,
        completion: (() -> Void)? = nil
    ) {
        print("[H5] [HumanScroll] 📌 准备滚动(自定义缓动): distance=\(distance)")
        
        let simulator = HumanScrollSimulator(scrollView: scrollView)
        simulator.easingFunction = easingFunction
        
        // 将模拟器添加到活跃实例容器中
        activeSimulators[simulator.id] = simulator
        
        simulator.startScrolling(
            distance: distance,
            duration: duration,
            completion: {
                // 在完成回调中移除模拟器实例
                activeSimulators.removeValue(forKey: simulator.id)
                print("[H5] [HumanScroll] 🧹 完成后移除模拟器: \(simulator.id), 剩余活跃模拟器: \(activeSimulators.count)")
                completion?()
            }
        )
    }
    
    /// 执行多段滑动，模拟更真实的人类浏览行为
    /// - Parameters:
    ///   - scrollView: 要滚动的 UIScrollView
    ///   - segments: 滑动段落数组，每个元素包含滑动距离、持续时间和停顿时间
    ///   - completion: 所有滑动完成后的回调
    static func simulateMultiStageScroll(
        on scrollView: UIScrollView,
        segments: [(distance: CGFloat, duration: TimeInterval, pauseDuration: TimeInterval)],
        completion: (() -> Void)? = nil
    ) {
        guard !segments.isEmpty else {
            print("[H5] [HumanScroll] ⚠️ 多段滑动段落为空")
            completion?()
            return
        }
        
        print("[H5] [HumanScroll] 🔄 开始多段滑动，共\(segments.count)段")
        executeScrollSegments(segments, on: scrollView, currentIndex: 0, completion: completion)
    }
    
    /// 执行滑动段落
    private static func executeScrollSegments(
        _ segments: [(distance: CGFloat, duration: TimeInterval, pauseDuration: TimeInterval)],
        on scrollView: UIScrollView,
        currentIndex: Int,
        completion: (() -> Void)?
    ) {
        // 检查是否完成所有滑动
        guard currentIndex < segments.count else {
            print("[H5] [HumanScroll] ✅ 完成所有滑动段落")
            completion?()
            return
        }
        
        // 获取当前段的滑动参数
        let segment = segments[currentIndex]
        print("[H5] [HumanScroll] 🔄 执行第 \(currentIndex + 1)/\(segments.count) 段滑动: 距离=\(segment.distance), 持续=\(segment.duration)秒")
        
        // 执行当前段的滑动
        simulateScroll(
            on: scrollView,
            distance: segment.distance,
            duration: segment.duration
        ) {
            // 如果有停顿时间，等待后继续下一段
            if segment.pauseDuration > 0 {
                print("[H5] [HumanScroll] ⏸️ 滑动停顿: \(segment.pauseDuration)秒")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + segment.pauseDuration) {
                    // 执行下一段滑动
                    executeScrollSegments(segments, on: scrollView, currentIndex: currentIndex + 1, completion: completion)
                }
            } else {
                // 直接执行下一段滑动
                executeScrollSegments(segments, on: scrollView, currentIndex: currentIndex + 1, completion: completion)
            }
        }
    }
    
    /// 创建智能滑动计划，根据内容长度自适应
    /// - Parameters:
    ///   - scrollView: 滚动视图
    ///   - maxScrolls: 最大滑动次数
    /// - Returns: 滑动计划
    static func createSmartScrollPlan(for scrollView: UIScrollView, maxScrolls: Int = 5) -> [(distance: CGFloat, duration: TimeInterval, pauseDuration: TimeInterval)] {
        var plan: [(distance: CGFloat, duration: TimeInterval, pauseDuration: TimeInterval)] = []
        
        // 计算可滚动范围
        let maxScrollOffset = max(0, scrollView.contentSize.height - scrollView.frame.height)
        let currentOffset = scrollView.contentOffset.y
        
        // 如果内容不足以滚动，返回空计划
        if maxScrollOffset <= 0 {
            print("[H5] [HumanScroll] ℹ️ 内容不足以滚动")
            return plan
        }
        
        // 判断是否为短页面
        let isShortPage = scrollView.contentSize.height < scrollView.frame.height * Config.shortPageThreshold
        print("[H5] [HumanScroll] 📏 页面类型: \(isShortPage ? "短页面" : "长页面"), 内容高度: \(scrollView.contentSize.height), 视图高度: \(scrollView.frame.height)")
        
        // 确定滑动次数 - 随机1-5次，短页面倾向于更少的滑动次数
        let minScrolls = isShortPage ? Config.shortPageMinScrolls : Config.longPageMinScrolls
        let maxActualScrolls = min(isShortPage ? 3 : maxScrolls, maxScrolls)
        let scrollCount = Int.random(in: minScrolls...maxActualScrolls)
        print("[H5] [HumanScroll] 🎲 随机决定滑动次数: \(scrollCount)次")
        
        // 计算剩余可滚动距离
        var remainingScrollDistance = maxScrollOffset - currentOffset
        
        // 创建向下滑动计划
        for i in 0..<scrollCount {
            // 如果已经滚动到底部，跳出循环
            if remainingScrollDistance <= 0 {
                break
            }
            
            // 决定是快速滑动还是慢速滑动
            let isFastScroll = CGFloat.random(in: 0...1) < Config.fastScrollProbability
            
            // 计算当前段的滑动距离
            var distanceRatio: CGFloat
            var duration: TimeInterval
            
            if isFastScroll {
                // 快速滑动 - 更大的距离，更短的时间
                distanceRatio = isShortPage ?
                CGFloat.random(in: 0.4...0.6) :
                CGFloat.random(in: 0.3...0.5) * Config.fastScrollDistanceMultiplier
                
                // 快速滑动持续时间 (0.7-1.3秒)
                duration = TimeInterval.random(in: 0.7...1.3) * Config.fastScrollSpeedMultiplier
                print("[H5] [HumanScroll] ⚡ 快速滑动段")
            } else {
                // 慢速滑动 - 较小的距离，较长的时间
                distanceRatio = isShortPage ?
                CGFloat.random(in: 0.2...0.4) :
                CGFloat.random(in: 0.15...0.3)
                
                // 慢速滑动持续时间 (1.5-2.5秒)
                duration = TimeInterval.random(in: 1.5...2.5)
                print("[H5] [HumanScroll] 🐢 慢速滑动段")
            }
            
            // 确定最大单次滑动距离，根据页面类型和滑动速度调整
            let maxDistance = isShortPage ?
            Config.shortPageMaxScrollDistance :
            (isFastScroll ? Config.maxScrollDistance * Config.fastScrollDistanceMultiplier : Config.maxScrollDistance)
            
            var distance = min(remainingScrollDistance * distanceRatio, maxDistance)
            
            // 确保滑动距离不小于最小值（除非剩余距离不足）
            distance = max(min(distance, remainingScrollDistance), min(Config.minScrollDistance, remainingScrollDistance))
            
            // 停顿时间，根据滑动速度调整
            let pauseDuration: TimeInterval
            if i < scrollCount - 1 {
                if isFastScroll {
                    // 快速滑动后的短暂停顿
                    pauseDuration = TimeInterval.random(in: Config.minPauseDuration...Config.minPauseDuration + 0.5)
                } else {
                    // 慢速滑动后的较长停顿
                    pauseDuration = TimeInterval.random(in: Config.minPauseDuration + 0.3...Config.maxPauseDuration)
                }
            } else {
                // 最后一段不需要停顿
                pauseDuration = 0
            }
            
            plan.append((distance: distance, duration: duration, pauseDuration: pauseDuration))
            remainingScrollDistance -= distance
            
            print("[H5] [HumanScroll] 📝 计划段 \(i+1): 距离=\(distance), 持续=\(duration)秒, 停顿=\(pauseDuration)秒")
        }
        
        // 如果已经滚动到底部且不是短页面，添加反向滑动
        if remainingScrollDistance <= 0 && !isShortPage && CGFloat.random(in: 0...1) < Config.reverseScrollProbability {
            // 计算已滑动的总距离
            let totalScrolled = maxScrollOffset - remainingScrollDistance
            
            // 计算反向滑动的距离（总滑动距离的一部分）
            let reverseDistance = -totalScrolled * CGFloat.random(in: 0.2...Config.reverseScrollRatio)
            
            // 反向滑动持续时间
            let reverseDuration = TimeInterval.random(in: 1.0...1.5)
            
            plan.append((distance: reverseDistance, duration: reverseDuration, pauseDuration: 0))
            print("[H5] [HumanScroll] 🔄 添加反向滑动: 距离=\(reverseDistance), 持续=\(reverseDuration)秒")
        }
        
        print("[H5] [HumanScroll] 📝 生成滑动计划: \(plan.count)段")
        return plan
    }
    
    // MARK: - 私有属性
    /// 唯一标识符
    private let id = UUID()
    
    /// 要滚动的 UIScrollView
    private weak var scrollView: UIScrollView?
    
    /// 滚动计时器
    private var scrollTimer: Timer?
    
    /// 缓动函数，默认使用三次贝塞尔缓动函数：缓入缓出
    private var easingFunction: (CGFloat) -> CGFloat = { x in
        return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }
    
    /// 滚动起始位置
    private var startOffset: CGFloat = 0
    
    /// 滚动目标位置
    private var targetOffset: CGFloat = 0
    
    /// 滚动完成回调
    private var completionHandler: (() -> Void)?
    
    // MARK: -
    /// 私有初始化方法
    private init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        print("[H5] [HumanScroll] 🔧 初始化滚动模拟器: ID: \(id)")
    }
    
    // MARK: -
    /// 开始滚动
    private func startScrolling(distance: CGFloat, duration: TimeInterval, completion: (() -> Void)?) {
        guard let scrollView = scrollView else {
            print("[H5] [HumanScroll] ❌ 滚动失败: scrollView 已被释放")
            completion?()
            return
        }
        
        // 计算可滚动范围和限制滚动距离
        let maxScrollOffset = max(0, scrollView.contentSize.height - scrollView.frame.height)
        let currentOffset = scrollView.contentOffset.y
        
        // 调整滚动距离，确保不会超出范围
        var adjustedDistance = distance
        
        // 向下滚动（正值）
        if distance > 0 {
            let remainingDistance = maxScrollOffset - currentOffset
            if remainingDistance <= 0 {
                print("[H5] [HumanScroll] ℹ️ 已到达底部，无法继续向下滚动")
                completion?()
                return
            }
            adjustedDistance = min(distance, remainingDistance)
        }
        // 向上滚动（负值）
        else if distance < 0 {
            let remainingDistance = currentOffset
            if remainingDistance <= 0 {
                print("[H5] [HumanScroll] ℹ️ 已到达顶部，无法继续向上滚动")
                completion?()
                return
            }
            adjustedDistance = max(distance, -remainingDistance)
        }
        // 距离为0，直接返回
        else {
            print("[H5] [HumanScroll] ℹ️ 滚动距离为0，跳过滚动")
            completion?()
            return
        }
        
        print("[H5] [HumanScroll] 🔄 开始模拟人类滚动，距离: \(adjustedDistance), 持续: \(duration)秒, ID: \(id)")
        
        // 保存滚动起始位置和目标位置
        startOffset = scrollView.contentOffset.y
        targetOffset = startOffset + adjustedDistance
        completionHandler = completion
        
        print("[H5] [HumanScroll] 📊 滚动参数: 起始位置=\(startOffset), 目标位置=\(targetOffset)")
        
        // 创建动画计时器
        var elapsedTime: TimeInterval = 0
        // 约60fps
        let interval: TimeInterval = 0.016
        
        // 记录上次更新时间，用于计算时间间隔
        var lastUpdateTime = Date()
        
        // 取消之前的计时器
        scrollTimer?.invalidate()
        
        // 创建一个定时器来执行缓动动画
        scrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self, weak scrollView] timer in
            guard let self = self, let scrollView = scrollView else {
                print("[H5] [HumanScroll] ❌ 计时器回调: scrollView 或 self 已被释放")
                timer.invalidate()
                return
            }
            
            // 计算实际经过的时间（防止定时器不准）
            let now = Date()
            let deltaTime = now.timeIntervalSince(lastUpdateTime)
            lastUpdateTime = now
            
            elapsedTime += deltaTime
            
            if elapsedTime >= duration {
                // 动画结束，确保精确到达目标位置
                let finalOffset = CGPoint(x: scrollView.contentOffset.x, y: self.targetOffset)
                scrollView.setContentOffset(finalOffset, animated: false)
                
                print("[H5] [HumanScroll] ✅ 滚动完成: 最终位置=\(scrollView.contentOffset), ID: \(self.id)")
                
                timer.invalidate()
                self.scrollTimer = nil
                
                // 调用完成回调
                self.completionHandler?()
                return
            }
            
            // 使用缓动函数计算当前位置
            let progress = CGFloat(elapsedTime / duration)
            let easedProgress = self.easingFunction(progress)
            
            // 添加一些随机微小变化，使滚动更像人类操作
            let isShortPage = scrollView.contentSize.height < scrollView.frame.height * Config.shortPageThreshold
            
            // 根据滚动进度调整随机性 - 开始和结束时随机性更大，中间部分更平滑
            let progressFactor = 1.0 - abs(progress - 0.5) * 2 // 在中间进度时接近0，两端接近1
            let baseRandomFactor = isShortPage ? 0.2 : 0.5
            let randomFactor = baseRandomFactor * (0.5 + progressFactor * 0.5) // 中间段降低随机性
            
            // 添加周期性的微小抖动，模拟手指在屏幕上的不稳定性
            let jitterPhase = sin(progress * 15) * 0.3
            let randomness = CGFloat.random(in: -randomFactor...randomFactor) + jitterPhase
            
            // 计算当前应该滚动到的位置
            let distance = self.targetOffset - self.startOffset
            let currentOffset = self.startOffset + (distance * easedProgress) + randomness
            let newOffset = CGPoint(x: scrollView.contentOffset.x, y: currentOffset)
            
            // 应用滚动（不使用动画，避免闪烁）
            scrollView.setContentOffset(newOffset, animated: false)
        }
        
        // 确保计时器不被立即释放
        RunLoop.current.add(scrollTimer!, forMode: .common)
        print("[H5] [HumanScroll] ⏱️ 计时器已添加到 RunLoop, ID: \(id)")
    }
    
    // MARK: - 析构函数
    deinit {
        print("[H5] [HumanScroll] 🗑️ 滚动模拟器被释放, ID: \(id)")
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
}

// MARK: - 预定义缓动函数
internal extension HumanScrollSimulator {
    
    /// 缓动函数类型
    enum EasingType {
        /// 线性缓动（匀速）
        case linear
        /// 缓入（慢开始）
        case easeIn
        /// 缓出（慢结束）
        case easeOut
        /// 缓入缓出（慢开始慢结束）
        case easeInOut
        /// 弹性缓动（带反弹效果）
        case elastic
        /// 弹跳缓动（像球体弹跳）
        case bounce
        
        /// 获取对应的缓动函数
        var function: (CGFloat) -> CGFloat {
            switch self {
            case .linear:
                return { $0 }
            case .easeIn:
                return { $0 * $0 * $0 }
            case .easeOut:
                return { let t = 1 - $0; return 1 - t * t * t }
            case .easeInOut:
                return { $0 < 0.5 ? 4 * $0 * $0 * $0 : 1 - pow(-2 * $0 + 2, 3) / 2 }
            case .elastic:
                return { x in
                    let c4 = CGFloat(2 * Double.pi / 3)
                    let pow = pow(2, 10 * Double(x) - 10)
                    let sin = sin((Double(x) * 10 - 10.75) * Double(c4))
                    return x == 0 ? 0 : x == 1 ? 1 : -CGFloat(pow) * CGFloat(sin)
                }
            case .bounce:
                return { x in
                    let n1: CGFloat = 7.5625
                    let d1: CGFloat = 2.75
                    var t = x
                    if t < 1 / d1 {
                        return n1 * t * t
                    } else if t < 2 / d1 {
                        t -= 1.5 / d1
                        return n1 * t * t + 0.75
                    } else if t < 2.5 / d1 {
                        t -= 2.25 / d1
                        return n1 * t * t + 0.9375
                    } else {
                        t -= 2.625 / d1
                        return n1 * t * t + 0.984375
                    }
                }
            }
        }
    }
    
    /// 使用预定义缓动类型模拟滚动
    /// - Parameters:
    ///   - scrollView: 要滚动的 UIScrollView
    ///   - distance: 滚动距离
    ///   - duration: 滚动持续时间
    ///   - easingType: 缓动类型
    ///   - completion: 滚动完成后的回调
    static func simulateScroll(
        on scrollView: UIScrollView,
        distance: CGFloat,
        duration: TimeInterval = 2.0,
        easingType: EasingType = .easeInOut,
        completion: (() -> Void)? = nil
    ) {
        simulateScroll(
            on: scrollView,
            distance: distance,
            duration: duration,
            easingFunction: easingType.function,
            completion: completion
        )
    }
}

// MARK: -
internal extension UIScrollView {
    
    /// 模拟人类滚动行为
    /// - Parameters:
    ///   - distance: 滚动距离
    ///   - duration: 滚动持续时间
    ///   - completion: 滚动完成后的回调
    func simulateHumanScroll(distance: CGFloat, duration: TimeInterval = 2.0, completion: (() -> Void)? = nil) {
        HumanScrollSimulator.simulateScroll(on: self, distance: distance, duration: duration, completion: completion)
    }
    
    /// 使用指定缓动类型模拟人类滚动行为
    /// - Parameters:
    ///   - distance: 滚动距离
    ///   - duration: 滚动持续时间
    ///   - easingType: 缓动类型
    ///   - completion: 滚动完成后的回调
    func simulateHumanScroll(
        distance: CGFloat,
        duration: TimeInterval = 2.0,
        easingType: HumanScrollSimulator.EasingType = .easeInOut,
        completion: (() -> Void)? = nil
    ) {
        HumanScrollSimulator.simulateScroll(
            on: self,
            distance: distance,
            duration: duration,
            easingType: easingType,
            completion: completion
        )
    }
    
    /// 执行多段滑动，模拟更真实的人类浏览行为
    /// - Parameters:
    ///   - segments: 滑动段落数组，每个元素包含滑动距离、持续时间和停顿时间
    ///   - completion: 所有滑动完成后的回调
    func simulateMultiStageScroll(
        segments: [(distance: CGFloat, duration: TimeInterval, pauseDuration: TimeInterval)],
        completion: (() -> Void)? = nil
    ) {
        HumanScrollSimulator.simulateMultiStageScroll(on: self, segments: segments, completion: completion)
    }
    
    /// 执行智能浏览模式，自动根据内容长度调整滑动行为
    /// - Parameters:
    ///   - maxScrolls: 最大滑动次数
    ///   - completion: 所有滑动完成后的回调
    func simulateSmartBrowsing(maxScrolls: Int = 5, completion: (() -> Void)? = nil) {
        // 创建智能滑动计划
        let scrollPlan = HumanScrollSimulator.createSmartScrollPlan(for: self, maxScrolls: maxScrolls)
        
        if scrollPlan.isEmpty {
            print("[H5] [HumanScroll] ℹ️ 无需滚动")
            completion?()
            return
        }
        
        // 执行滑动计划
        simulateMultiStageScroll(segments: scrollPlan, completion: completion)
    }
    
    /// 模拟真实阅读行为，先停留一段时间，然后开始智能滚动
    /// - Parameters:
    ///   - initialPause: 初始停留时间，默认为随机1-3秒
    ///   - maxScrolls: 最大滑动次数，默认为5
    ///   - completion: 所有滑动完成后的回调
    func simulateRealisticReading(initialPause: TimeInterval? = nil, maxScrolls: Int = 5, completion: (() -> Void)? = nil) {
        // 确定初始停留时间
        let pauseTime = initialPause ?? TimeInterval.random(in: 1.0...3.0)
        
        print("[H5] [HumanScroll] 👀 开始模拟真实阅读行为: 初始停留\(pauseTime)秒")
        
        // 先停留一段时间，然后开始滚动
        DispatchQueue.main.asyncAfter(deadline: .now() + pauseTime) { [weak self] in
            guard let self = self else {
                print("[H5] [HumanScroll] ⚠️ ScrollView已被释放，无法执行阅读模拟")
                completion?()
                return
            }
            
            // 开始智能滚动
            self.simulateSmartBrowsing(maxScrolls: maxScrolls, completion: completion)
        }
    }
}

