//
//  UIView+Constraints.swift
//  GrowthSDK
//
//  Created by arvin on 2025/5/23.
//

import UIKit
import ObjectiveC

/// UIView 约束扩展
/// 提供链式调用风格的自动布局API，简化约束的创建和管理
internal extension UIView {
    
    // MARK: - 边距约束
    
    /// 将视图固定到另一个视图的边缘
    /// - Parameters:
    ///   - view: 参考视图
    ///   - insets: 边距，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func pin(to view: UIView, insets: UIEdgeInsets = .zero) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right)
        ])
        return self
    }
    
    /// 将视图固定到另一个视图的安全区域
    /// - Parameters:
    ///   - view: 参考视图
    ///   - insets: 边距，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func pinToSafeArea(of view: UIView, insets: UIEdgeInsets = .zero) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: insets.left),
            bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -insets.bottom),
            trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -insets.right)
        ])
        return self
    }
    
    // MARK: - 尺寸约束
    
    /// 设置视图的尺寸
    /// - Parameter size: 尺寸大小
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func size(_ size: CGSize) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ])
        return self
    }
    
    /// 设置视图的宽度
    /// - Parameter width: 宽度值
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func width(_ width: CGFloat) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: width).isActive = true
        return self
    }
    
    /// 设置视图的高度
    /// - Parameter height: 高度值
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func height(_ height: CGFloat) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
        return self
    }
    
    // MARK: - 位置约束
    
    /// 将视图居中于另一个视图
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func center(in view: UIView, offset: CGPoint = .zero) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset.x),
            centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset.y)
        ])
        return self
    }
    
    /// 设置视图在X轴上的居中位置
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: X轴偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func centerX(to view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset).isActive = true
        return self
    }
    
    /// 设置视图在Y轴上的居中位置
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: Y轴偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func centerY(to view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset).isActive = true
        return self
    }
    
    // MARK: - 边缘约束 (RTL支持)
    
    /// 设置视图的顶部约束
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 顶部偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func top(to view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: view.topAnchor, constant: offset).isActive = true
        return self
    }
    
    /// 设置视图的底部约束
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 底部偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func bottom(to view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -offset).isActive = true
        return self
    }
    
    /// 设置视图的前缘约束（适用于RTL布局）
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 前缘偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func leading(to view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: offset).isActive = true
        return self
    }
    
    /// 设置视图的后缘约束（适用于RTL布局）
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 后缘偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func trailing(to view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -offset).isActive = true
        return self
    }
    
    /// 设置视图的水平两侧约束（适用于RTL布局）
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 后缘偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func horizontal(to view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: offset),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -offset)
        ])
        return self
    }
    
    /// 设置视图的垂直上下约束（适用于RTL布局）
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 后缘偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func vertical(to view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: offset),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -offset)
        ])
        return self
    }
    
    // MARK: - LTR特定约束 (不自动适应RTL)
    
    /// 设置视图的左侧约束（不自动适应RTL布局）
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 左侧偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func left(to view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        leftAnchor.constraint(equalTo: view.leftAnchor, constant: offset).isActive = true
        return self
    }
    
    /// 设置视图的右侧约束（不自动适应RTL布局）
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 右侧偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func right(to view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        rightAnchor.constraint(equalTo: view.rightAnchor, constant: -offset).isActive = true
        return self
    }
    
    // MARK: - 高级约束
    
    /// 设置视图相对于另一个视图顶部的约束
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func topToBottom(of view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: view.bottomAnchor, constant: offset).isActive = true
        return self
    }
    
    /// 设置视图相对于另一个视图底部的约束
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func bottomToTop(of view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        bottomAnchor.constraint(equalTo: view.topAnchor, constant: -offset).isActive = true
        return self
    }
    
    /// 设置视图相对于另一个视图前缘的约束（支持RTL布局）
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func leadingToTrailing(of view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: view.trailingAnchor, constant: offset).isActive = true
        return self
    }
    
    /// 设置视图相对于另一个视图后缘的约束（支持RTL布局）
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func trailingToLeading(of view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        trailingAnchor.constraint(equalTo: view.leadingAnchor, constant: -offset).isActive = true
        return self
    }
    
    /// 设置视图相对于另一个视图左侧的约束（不自动适应RTL布局）
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func leftToRight(of view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        leftAnchor.constraint(equalTo: view.rightAnchor, constant: offset).isActive = true
        return self
    }
    
    /// 设置视图相对于另一个视图右侧的约束（不自动适应RTL布局）
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 偏移量，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func rightToLeft(of view: UIView, offset: CGFloat = 0) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        rightAnchor.constraint(equalTo: view.leftAnchor, constant: -offset).isActive = true
        return self
    }
    
    // MARK: - 链式约束存储
    private struct AssociatedKeys {
        static let constraintsKey = UnsafeRawPointer(bitPattern: "UIView.Constraints.Key".hashValue)!
    }
    
    private var storedConstraints: [NSLayoutConstraint] {
        get {
            return objc_getAssociatedObject(self, AssociatedKeys.constraintsKey) as? [NSLayoutConstraint] ?? []
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.constraintsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - 约束组
    
    /// 批量设置约束
    /// - Parameter block: 约束设置闭包
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func makeConstraints(_ block: (UIView) -> Void) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        block(self)
        return self
    }
    
    /// 存储约束以便后续更新
    /// - Parameter constraint: 要存储的约束
    /// - Returns: 存储的约束
    @discardableResult
    func store(_ constraint: NSLayoutConstraint) -> NSLayoutConstraint {
        constraint.isActive = true
        var constraints = storedConstraints
        constraints.append(constraint)
        storedConstraints = constraints
        return constraint
    }
    
    /// 更新已存储的约束常量
    /// - Parameters:
    ///   - index: 约束索引
    ///   - constant: 新的常量值
    func updateStoredConstraint(at index: Int, constant: CGFloat) {
        guard index < storedConstraints.count else { return }
        storedConstraints[index].constant = constant
    }
    
    // MARK: - 便捷方法
    
    /// 添加子视图并设置约束
    /// - Parameters:
    ///   - view: 要添加的子视图
    ///   - insets: 边距，默认为零
    /// - Returns: 自身，用于链式调用
    @discardableResult
    func addSubviewWithConstraints(_ view: UIView, insets: UIEdgeInsets = .zero) -> Self {
        addSubview(view)
        view.pin(to: self, insets: insets)
        return self
    }
}

/// 边距辅助扩展
internal extension UIEdgeInsets {
    
    /// 创建四边相等的边距
    /// - Parameter value: 边距值
    /// - Returns: 边距对象
    static func all(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: value, left: value, bottom: value, right: value)
    }
    
    /// 创建水平和垂直边距
    /// - Parameters:
    ///   - value: 水平边距值（左右）
    ///   - vertical: 垂直边距值（上下），默认为零
    /// - Returns: 边距对象
    static func horizontal(_ value: CGFloat, vertical: CGFloat = 0) -> UIEdgeInsets {
        return UIEdgeInsets(top: vertical, left: value, bottom: vertical, right: value)
    }
    
    /// 创建垂直和水平边距
    /// - Parameters:
    ///   - value: 垂直边距值（上下）
    ///   - horizontal: 水平边距值（左右），默认为零
    /// - Returns: 边距对象
    static func vertical(_ value: CGFloat, horizontal: CGFloat = 0) -> UIEdgeInsets {
        return UIEdgeInsets(top: value, left: horizontal, bottom: value, right: horizontal)
    }
    
}
