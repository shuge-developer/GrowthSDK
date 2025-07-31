//
//  TaskTypeable.swift
// GameWrapper
//
//  Created by arvin on 2025/6/6.
//

import Foundation
internal import SmartCodable

// MARK: - TaskType枚举
/// H5任务类型枚举
///
/// 定义了6种不同的任务操作类型，涵盖了用户在H5页面上的所有可能行为：
/// - 纯展示类：只加载显示，不进行任何交互
/// - 纯点击类：直接点击，不需要滑动
/// - 纯滑动类：只滑动浏览，不点击
/// - 组合操作类：先滑动再点击
///
/// 枚举值设计说明：
/// - 基础值(0-2)：单一操作类型
/// - 组合值(3-5)：滑动+其他操作的组合
internal enum TaskType: Int16, SmartCaseDefaultable {
    /// 页面展示
    /// 场景：只加载H5页面并展示一段时间，不进行任何用户交互
    /// 适用：flag=0 且功能点击概率判断为否的情况
    case show = 0
    
    /// 广告点击
    /// 场景：直接点击页面上的广告区域，不需要滑动
    /// 适用：flag=1 且有广告目标(id/type) 且首屏可见且不需要滑动
    case aClick = 1
    
    /// 功能点击
    /// 场景：点击页面上的功能按钮或功能区域，不需要滑动
    /// 适用：flag=1 且无广告目标 或 flag=0 且功能点击概率判断为是，且不需要滑动
    case fClick = 2
    
    /// 页面滑动
    /// 场景：在页面上执行滑动操作，但不点击任何内容
    /// 适用：需要滑动 且 基础操作类型为show的情况
    case move = 3
    
    /// 滑动+广告点击
    /// 场景：先滑动页面找到广告，然后点击广告
    /// 适用：需要滑动 且 基础操作类型为aClick的情况
    case mAClick = 4
    
    /// 滑动+功能点击
    /// 场景：先滑动页面找到功能区，然后点击功能
    /// 适用：需要滑动 且 基础操作类型为fClick的情况
    case mFClick = 5
}

// MARK: - TaskType计算协议
/// 负责计算每条链接TaskType的协议
internal protocol TaskTypeable {
    /// 计算TaskType
    /// - Parameter initConfig: 远程的配置模型
    /// - Parameter cacheCfg: 缓存的配置模型
    /// - Returns: 计算得出的TaskType
    func calculateTaskType(with initConfig: H5InitConfig?, cacheCfg: InitConfig?) -> TaskType
}

// MARK: - TaskType计算器
internal struct TaskTypeCalculator {
    
    /// 计算链接数据的TaskType
    ///
    /// 计算逻辑分为三个步骤：
    /// 1. 判断是否需要滑动（基于屏幕类型和滑动概率）
    /// 2. 判断点击类型（基于flag标志和功能概率）
    /// 3. 组合最终的TaskType（滑动+点击的组合）
    ///
    /// - Parameters:
    ///   - linkData: 链接数据，包含屏幕类型、点击标志等信息
    ///   - configModel: H5配置模型，包含概率配置等
    /// - Returns: 计算得出的TaskType枚举值
    static func calculate(for linkData: H5LinkData, with initConfig: H5InitConfig?, cacheCfg: InitConfig?) -> TaskType {
        let slideRate = initConfig?.slideRate ?? cacheCfg?.slideRate ?? 0.5
        let function = initConfig?.function ?? cacheCfg?.function ?? 0.5
        
        let clickType = determineClickType(linkData: linkData, funcRate: function)
        let needMove = shouldMove(linkData: linkData, slideRate: slideRate)
        
        let type = combineTaskType(needMove: needMove, clickType: clickType)
        print("[H5] [TaskType] type: \(type)")
        return type
    }
    
    // MARK: - 私有计算方法
    
    /// 判断是否需要滑动
    ///
    /// 滑动判断规则：
    /// - 如果 screenType = 1（首屏不可见），则必须滑动才能看到内容
    /// - 如果 screenType = 0（首屏可见），则通过 slideRate 概率随机判断
    ///   * 生成 0~1 的随机数，如果随机数 <= slideRate，则需要滑动
    ///   * 例如：slideRate = 0.3，则有30%的概率需要滑动
    ///
    /// - Parameters:
    ///   - linkData: 链接数据，主要使用其 screenType 字段
    ///   - slideRate: 滑动概率，取值范围 0~1
    /// - Returns: true=需要滑动，false=不需要滑动
    private static func shouldMove(linkData: H5LinkData, slideRate: Double) -> Bool {
        // 首屏不可见广告，用户必须先滑动才能看到广告内容
        guard linkData.screenType != 1 else { return true }
        
        // 首屏可见广告，通过概率判断是否模拟用户滑动行为
        // 使用随机数模拟真实用户的滑动习惯
        let random = Double.random(in: 0...1)
        print("[H5] link: \(linkData.link), 滑动随机数：\(random), 滑动概率：\(slideRate)")
        return random <= slideRate
    }
    
    /// 判断点击类型
    ///
    /// 点击类型判断规则：
    /// 1. 如果 flag = 1（强制点击），则进一步判断：
    ///    - 如果有广告目标（id、type等不为空），则执行广告点击
    ///    - 如果没有广告目标，则执行功能点击
    ///
    /// 2. 如果 flag = 0（不强制点击），则通过 funcRate 概率判断：
    ///    - 生成 0~1 的随机数，如果随机数 <= funcRate，则执行功能点击
    ///    - 否则只展示不点击
    ///
    /// - Parameters:
    ///   - linkData: 链接数据，使用 flag、id、type 等字段
    ///   - funcRate: 功能点击概率，取值范围 0~1
    /// - Returns: TaskType枚举值（.show/.aClick/.fClick）
    private static func determineClickType(linkData: H5LinkData, funcRate: Double) -> TaskType {
        // flag=1 表示配置要求必须点击
        if linkData.flag == 1 {
            // 判断是否有明确的广告目标（广告ID或广告类型）
            // 如果有广告目标，执行广告点击；否则执行功能点击
            return linkData.hasAdTarget ? .aClick : .fClick
        }
        
        // flag=0 表示配置允许不点击，通过概率模拟用户行为
        // 使用随机数决定是否执行功能点击，模拟真实用户的点击习惯
        let random = Double.random(in: 0...1)
        print("[H5] link: \(linkData.link), 功能随机数：\(random), 功能点击概率：\(funcRate)")
        if random <= funcRate {
            return .fClick
        } else {
            return .show
        }
    }
    
    /// 组合最终的TaskType
    ///
    /// 组合规则：
    /// - 如果不需要滑动：直接返回点击类型（.show/.aClick/.fClick）
    /// - 如果需要滑动：返回滑动+点击的组合类型
    ///   * .show → .move（只滑动不点击）
    ///   * .aClick → .mAClick（滑动+广告点击）
    ///   * .fClick → .mFClick（滑动+功能点击）
    ///
    /// 这样设计可以完整描述用户的操作流程：先滑动，再执行相应的点击动作
    ///
    /// - Parameters:
    ///   - needMove: 是否需要滑动
    ///   - clickType: 基础点击类型
    /// - Returns: 最终的TaskType枚举值
    private static func combineTaskType(needMove: Bool, clickType: TaskType) -> TaskType {
        // 如果不需要滑动，直接返回基础点击类型
        guard needMove else { return clickType }
        
        // 需要滑动时，将滑动动作与点击动作组合
        switch clickType {
        case .show: return .move      // 只滑动，不点击
        case .aClick: return .mAClick // 滑动后点击广告
        case .fClick: return .mFClick // 滑动后点击功能区
        default: return .move         // 兜底：默认只滑动
        }
    }
}

// MARK: -
internal extension H5LinkData {
    
    /// 判断是否有明确的广告目标
    ///
    /// 广告目标判断逻辑：
    /// - id: 广告ID，如果不为空说明有具体的广告要点击
    /// - type: 广告类型，如果不为空说明要点击某种类型的广告
    ///
    /// 使用场景：
    /// - 当 flag=1 且 hasAdTarget=true 时，执行广告点击(.aClick)
    /// - 当 flag=1 且 hasAdTarget=false 时，执行功能点击(.fClick)
    ///
    /// - Returns: true=有广告目标，false=无广告目标
    var hasAdTarget: Bool {
        var result = [id, type].compactMap { $0 }.contains { !$0.isEmpty }
        if result == false { // 无广告目标，继续判断是否有兜底广告区域
            if let zone, !zone.isEmpty { // 有兜底区域
                result = true
            }
        }
        return result
    }
    
}
