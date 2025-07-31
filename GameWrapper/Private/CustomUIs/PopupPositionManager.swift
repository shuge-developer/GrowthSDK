//
//  PopupPositionManager.swift
//  SmallGame
//
//  Created by arvin on 2025/6/12.
//

import Foundation
import Combine
import UIKit

// MARK: -
/// 弹窗位置管理器
/// 负责根据广告区域动态确定弹窗的位置和类型
final class PopupPositionManager: ObservableObject {
    
    // MARK: - 单例
    static let shared = PopupPositionManager()
    
    // MARK: - 发布者
    /// 弹窗位置信息发布者
    private let popupPositionSubject = CurrentValueSubject<PopupPositionInfo, Never>(PopupPositionInfo())
    
    /// 弹窗位置信息发布者（只读）
    public var popupPositionPublisher: AnyPublisher<PopupPositionInfo, Never> {
        return popupPositionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - 属性
    /// 当前弹窗位置信息
    public var currentPositionInfo: PopupPositionInfo {
        return popupPositionSubject.value
    }
    
    /// 屏幕尺寸
    private let screenSize = UIScreen.main.bounds.size
    
    // MARK: - 初始化
    private init() {}
    
    // MARK: - 公共方法
    /// 根据广告区域更新弹窗位置
    /// - Parameter adArea: 广告区域
    func updatePopupPosition(for area: AdArea) {
        let position = determinePopupPosition(for: area)
        let centerPoint = calculatePopupCenter(for: area, position: position)
        let positionInfo = PopupPositionInfo(
            position: position,
            centerPoint: centerPoint,
            adArea: area
        )
        popupPositionSubject.send(positionInfo)
        print("[PopupPositionManager] 📍 更新弹窗位置: position=\(position), centerPoint=\(centerPoint)")
    }
    
    // MARK: - 私有方法
    /// 确定弹窗位置类型
    /// - Parameter area: 广告区域
    /// - Returns: 弹窗位置类型
    private func determinePopupPosition(for area: AdArea) -> Position {
        // 获取广告区域的中心点Y坐标
        let adCenterY = area.center.y
        
        // 获取广告区域的高度
        let adHeight = area.height
        
        // 获取屏幕高度
        let screenHeight = screenSize.height
        
        // 顶部区域阈值（屏幕高度的30%）
        let topThreshold = screenHeight * 0.2
        
        // 底部区域阈值（屏幕高度的70%）
        let bottomThreshold = screenHeight * 0.8
        
        // 锚定广告的高度阈值
        let anchorHeightThreshold: CGFloat = 120
        
        // 判断是否为顶部或底部锚定的广告（高度较小的广告）
        if adHeight < anchorHeightThreshold {
            // 对于小高度广告，根据Y坐标判断是顶部还是底部
            if adCenterY < screenHeight * 0.5 {
                // 广告在屏幕上半部分，认为是顶部锚定
                print("[PopupPositionManager] 📌 检测到顶部锚定广告（高度=\(adHeight)，中心Y=\(adCenterY)），使用顶部弹窗")
                return .top
            } else {
                // 广告在屏幕下半部分，认为是底部锚定
                print("[PopupPositionManager] 📌 检测到底部锚定广告（高度=\(adHeight)，中心Y=\(adCenterY)），使用底部弹窗")
                return .bottom
            }
        }
        
        // 对于非锚定广告（高度较大的广告），使用原有的判断逻辑
        if adCenterY < topThreshold {
            // 广告在屏幕顶部
            print("[PopupPositionManager] 📌 广告在顶部区域（高度=\(adHeight)，中心Y=\(adCenterY)），使用顶部弹窗")
            return .top
        } else if adCenterY > bottomThreshold {
            // 广告在屏幕底部
            print("[PopupPositionManager] 📌 广告在底部区域（高度=\(adHeight)，中心Y=\(adCenterY)），使用底部弹窗")
            return .bottom
        } else {
            // 广告在屏幕中间
            print("[PopupPositionManager] 📌 广告在中间区域（高度=\(adHeight)，中心Y=\(adCenterY)），使用中心弹窗")
            return .center
        }
    }
    
    /// 计算弹窗中心点
    /// - Parameters:
    ///   - area: 广告区域
    ///   - position: 弹窗位置类型
    /// - Returns: 弹窗中心点
    private func calculatePopupCenter(for area: AdArea, position: Position) -> CGPoint {
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        // 打印调试信息
        print("[PopupPositionManager] 📊 广告区域: left=\(area.left), top=\(area.top), width=\(area.width), height=\(area.height)")
        print("[PopupPositionManager] 📊 广告中心点: \(area.center)")
        print("[PopupPositionManager] 📊 调整后的广告中心点Y: \(area.getAdjustedCenterY())")
        
        switch position {
        case .top:
            // 顶部弹窗：使用默认位置，不进行动态调整
            // 这与 CustomPopupView.popupPosition() 中的实现保持一致
            let topY = 100.0  // popupSize.height/2
            print("[PopupPositionManager] 📐 顶部弹窗使用默认位置: Y=\(topY)")
            return CGPoint(x: screenWidth/2, y: topY)
            
        case .center:
            // 中心弹窗：直接使用广告区域的中心点
            let adCenterY = area.getAdjustedCenterY()
            print("[PopupPositionManager] 📐 中心弹窗Y位置: \(adCenterY)")
            return CGPoint(x: screenWidth/2, y: adCenterY)
            
        case .bottom:
            // 底部弹窗：使用默认位置，不进行动态调整
            // 这与 CustomPopupView.popupPosition() 中的实现保持一致
            let bottomY = screenHeight - 100.0  // screenHeight - popupSize.height/2
            print("[PopupPositionManager] 📐 底部弹窗使用默认位置: Y=\(bottomY)")
            return CGPoint(x: screenWidth/2, y: bottomY)
        }
    }
}

// MARK: -
/// 弹窗位置信息
struct PopupPositionInfo {
    /// 弹窗位置类型
    var position: Position = .center
    
    /// 弹窗中心点
    var centerPoint: CGPoint = CGPoint(
        x: UIScreen.main.bounds.width  / 2,
        y: UIScreen.main.bounds.height / 2
    )
    
    /// 关联的广告区域
    var adArea: AdArea? = nil
}
