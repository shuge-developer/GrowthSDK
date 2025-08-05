//
//  CustomPopupView.swift
//  GameWrapper
//
//  Created by arvin on 2025/6/12.
//

import SwiftUI
import Combine
import UIKit

// MARK: -
enum Position {
    case top, center, bottom
    
    var alignment: Alignment {
        switch self {
        case .top: return .top
        case .center: return .center
        case .bottom: return .bottom
        }
    }
}

// MARK: -
struct CustomPopupView: View {
    
    /// 背景遮罩颜色
    private var background: Color = .black.opacity(0.5)
    
    /// 手机屏幕宽度
    private var mainWidth = UIScreen.main.bounds.width
    
    /// 手机屏幕高度
    private var mainHeight = UIScreen.main.bounds.height
    
    /// 中间弹窗宽度
    private var popupWidth: CGFloat = 342
    
    /// 镂空的区域
    private var maskFrame: CGRect {
        switch position {
        case .top:
            CGRect(x: 25, y: 48, width: mainWidth - 50, height: 90)
        case .center:
            CGRect(x: 10, y: 150, width: popupWidth - 20, height: 100)
        case .bottom:
            CGRect(x: 25, y: 53, width: mainWidth - 50, height: 90)
        }
    }
    
    /// 弹窗 size
    private var popupSize: CGSize {
        switch position {
        case .top, .bottom:
            return CGSize(width: mainWidth, height: 200)
        case .center:
            return CGSize(width: popupWidth, height: 282)
        }
    }
    
    /// 是否显示弹窗
    @State private var isShowing: Bool = false
    
    /// 是否显示镂空区域
    @State private var showHole: Bool = false
    
    /// 自定义弹窗中心点（仅用于中心弹窗）
    @State private var customCenter: CGPoint?
    
    /// 弹窗位置
    @State private var position: Position
    
    /// 位置管理器
    private let positionManager = PopupPositionManager.shared
    
    /// 取消订阅集合
    @State private var cancellables = Set<AnyCancellable>()
    
    /// 关闭弹窗回调
    public var onClose: (() -> Void)?
    
    init(position: Position = .center, onClose: (() -> Void)? = nil) {
        self._position = State(initialValue: position)
        self.onClose = onClose
    }
    
    // MARK: -
    var body: some View {
        ZStack {
            /// 弹窗背景遮罩
            FullScreenMaskView(
                background: background,
                maskFrame: maskFrame,
                popupSize: popupSize,
                customCenter: customCenter,
                position: position,
                showHole: showHole
            )
            .id("mask_view_\(position)")
            .opacity(isShowing ? 1 : 0)
            
            /// 弹窗内容视图
            PopupContentView(
                position: position,
                maskFrame: maskFrame,
                showHole: showHole,
                onClose: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        showHole = false
                    }
                    _animation(.easeInOut(duration: 0.3), 0.3) {
                        isShowing = false
                    } completion: {
                        onClose?()
                    }
                }
            )
            .id("popup_content_\(position)")
            .frame(
                width: popupSize.width,
                height: popupSize.height
            )
            .position(popupPosition())
            .offset(y: offsetForPosition())
            .scaleEffect(position == .center ? (isShowing ? 1 : 0.5) : 1)
            .cornerRadius(position == .center ? 20 : 0)
            .opacity(isShowing ? 1 : 0)
        }
        .onAppear {
            setupPositionPublisher()
            startShowAnimation()
        }
    }
    
    private func setupPositionPublisher() {
        positionManager.popupPositionPublisher
            .receive(on: RunLoop.main)
            .sink { positionInfo in
                if positionInfo.position == .center {
                    self.customCenter = positionInfo.centerPoint
                } else {
                    self.customCenter = nil
                }
                self.position = positionInfo.position
            }
            .store(in: &cancellables)
    }
    
    private func startShowAnimation() {
        let animationDuration: Double = position == .center ? 0.3 : 0.5
        DispatchQueue.main.async {
            switch self.position {
            case .center:
                withAnimation(.spring(response: animationDuration, dampingFraction: 0.7)) {
                    self.isShowing = true
                }
            case .top, .bottom:
                withAnimation(.easeInOut(duration: animationDuration)) {
                    self.isShowing = true
                }
            }
            DispatchQueue.mainAsyncAfter(animationDuration) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.showHole = true
                }
            }
        }
    }
    
    private func popupPosition() -> CGPoint {
        let offsetY = popupSize.height / 2
        switch position {
        case .top:
            return CGPoint(x: mainWidth / 2, y: offsetY)
        case .center:
            guard let customCenter = customCenter, !customCenter.isZero else {
                return CGPoint(x: mainWidth / 2, y: mainHeight / 2)
            }
            return customCenter
        case .bottom:
            return CGPoint(x: mainWidth / 2, y: mainHeight - offsetY)
        }
    }
    
    private func offsetForPosition() -> CGFloat {
        switch position {
        case .top:
            return isShowing ? 0 : -popupSize.height
        case .center:
            return 0
        case .bottom:
            return isShowing ? 0 : popupSize.height
        }
    }
}

// MARK: -
private struct FullScreenMaskView: UIViewRepresentable {
    var background: Color
    var maskFrame: CGRect
    var popupSize: CGSize
    var customCenter: CGPoint?
    var position: Position
    var showHole: Bool
    
    func makeUIView(context: Context) -> FullScreenHoleView {
        let view = FullScreenHoleView()
        view.maskFrame = convertToCoordinates(maskFrame)
        view.backColor = UIColor(background)
        view.showHole = showHole
        return view
    }
    
    func updateUIView(_ uiView: FullScreenHoleView, context: Context) {
        uiView.maskFrame = convertToCoordinates(maskFrame)
        uiView.backColor = UIColor(background)
        uiView.showHole = showHole
        uiView.setNeedsLayout()
    }
    
    private func convertToCoordinates(_ frame: CGRect) -> CGRect {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        switch position {
        case .top:
            return CGRect(
                x: frame.minX,
                y: frame.minY,
                width: frame.width,
                height: frame.height
            )
        case .center:
            if let customCenter = customCenter {
                let popupX = customCenter.x - popupSize.width / 2
                let popupY = customCenter.y - popupSize.height / 2
                return CGRect(
                    x: popupX + frame.minX,
                    y: popupY + frame.minY,
                    width: frame.width,
                    height: frame.height
                )
            } else {
                let popupX = (screenWidth - popupSize.width) / 2
                let popupY = (screenHeight - popupSize.height) / 2
                return CGRect(
                    x: popupX + frame.minX,
                    y: popupY + frame.minY,
                    width: frame.width,
                    height: frame.height
                )
            }
        case .bottom:
            let bottomY = screenHeight - popupSize.height
            return CGRect(
                x: frame.minX,
                y: bottomY + frame.minY,
                width: frame.width,
                height: frame.height
            )
        }
    }
}

private class FullScreenHoleView: UIView {
    
    private var maskLayer: CAShapeLayer?
    
    var backColor: UIColor = .black.opacity(0.5) {
        didSet {
            backgroundColor = backColor
        }
    }
    
    var maskFrame: CGRect = .zero {
        didSet {
            if maskFrame != oldValue {
                updateMaskLayer()
            }
        }
    }
    
    var showHole: Bool = false {
        didSet {
            if showHole != oldValue {
                UIView.animate(withDuration: 0.25) {
                    self.updateMaskLayer()
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = backColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateMaskLayer()
    }
    
    // MARK: -
    private func updateMaskLayer() {
        maskLayer?.removeFromSuperlayer()
        let mask = CAShapeLayer()
        let path = UIBezierPath(rect: bounds)
        if showHole {
            let buttonPath = UIBezierPath(roundedRect: maskFrame, cornerRadius: 0)
            path.append(buttonPath.reversing())
        }
        mask.path = path.cgPath
        mask.fillRule = .evenOdd
        self.layer.mask = mask
        self.maskLayer = mask
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if showHole && maskFrame.contains(point) { return nil }
        return super.hitTest(point, with: event)
    }
    
}

// MARK: -
private struct PopupContentView: UIViewRepresentable {
    var position: Position
    var maskFrame: CGRect
    var showHole: Bool
    
    var onClose: (() -> Void)?
    
    func makeUIView(context: Context) -> BasePopupView {
        switch position {
        case .top:
            let view = TopView()
            view.maskFrame = maskFrame
            view.showHole = showHole
            view.onClose = onClose
            return view
            
        case .center:
            let view = CenterView()
            view.maskFrame = maskFrame
            view.showHole = showHole
            view.onClose = onClose
            return view
            
        case .bottom:
            let view = BottomView()
            view.maskFrame = maskFrame
            view.showHole = showHole
            view.onClose = onClose
            return view
        }
    }
    
    func updateUIView(_ uiView: BasePopupView, context: Context) {
        uiView.maskFrame = maskFrame
        uiView.showHole = showHole
        uiView.onClose = onClose
        uiView.updateUI()
    }
}

// MARK: - 基础弹窗视图类
private class BasePopupView: UIView {
    
    var maskFrame: CGRect = .zero {
        didSet {
            if maskFrame != oldValue {
                updateHoleView()
            }
        }
    }
    
    var showHole: Bool = false {
        didSet {
            if showHole != oldValue {
                updateHoleView()
            }
        }
    }
    
    var onClose: (() -> Void)?
    
    private var tapPublisher = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = .clear
        setupPublishers()
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupSubviews() {
        addSubview(bgImageView)
        addSubview(holeView)
    }
    
    func updateUI() {
        setNeedsLayout()
    }
    
    private func updateHoleView() {
        if showHole {
            holeView.frame = maskFrame
            holeView.isHidden = false
        } else {
            holeView.isHidden = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func setupPublishers() {
        tapPublisher
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .throttle(for: .milliseconds(500), scheduler: RunLoop.main, latest: false)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.onClose?()
            }
            .store(in: &cancellables)
    }
    
    @objc func close(_ sender: UIButton) {
        tapPublisher.send()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if showHole && maskFrame.contains(point) {
            tapPublisher.send()
            return nil
        }
        return super.hitTest(point, with: event)
    }
    
    // MARK: -
    private(set) lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(close(_:)), for: .touchUpInside)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .gray
        return button
    }()
    
    private(set) lazy var bgImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.isUserInteractionEnabled = false
        return imgView
    }()
    
    private lazy var holeView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
#if DEBUG
        view.layer.borderColor = UIColor.red.cgColor
        view.layer.borderWidth = 1
#endif
        return view
    }()
    
}

// MARK: - 顶部弹窗视图
private class TopView: BasePopupView {
    
    override func setupSubviews() {
        super.setupSubviews()
        let img = UIImage.named("ic_normal_bg")
        bgImageView.image = img
        addSubview(contentView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgImageView.makeConstraints {
            $0.horizontal(to: self, offset: 16)
                .top(to: self, offset: 44)
                .height(100)
        }
        contentView.makeConstraints {
            $0.horizontal(to: self, offset: 30)
                .center(in: bgImageView)
        }
    }
    
    // MARK: -
    private lazy var contentView: UIView = {
        let view = TopLoadingView()
        let controller = UIHostingController(rootView: view)
        controller.view.isUserInteractionEnabled = false
        controller.view.backgroundColor = .clear
        return controller.view
    }()
    
}

// MARK: - 中间弹窗视图
private class CenterView: BasePopupView {
    
    override func setupSubviews() {
        super.setupSubviews()
        let img = UIImage.named("ic_center_bg")
        bgImageView.image = img
        addSubview(contentView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgImageView.pin(to: self)
        contentView.makeConstraints {
            $0.horizontal(to: self, offset: 30)
                .center(in: self)
        }
    }
    
    // MARK: -
    private lazy var contentView: UIView = {
        let view = CenterNetTipsView()
        let controller = UIHostingController(rootView: view)
        controller.view.isUserInteractionEnabled = false
        controller.view.backgroundColor = .clear
        return controller.view
    }()
    
}

// MARK: - 底部弹窗视图
private class BottomView: BasePopupView {
    
    override func setupSubviews() {
        super.setupSubviews()
        let img = UIImage.named("ic_normal_bg")
        bgImageView.image = img
        addSubview(contentView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgImageView.makeConstraints {
            $0.horizontal(to: self, offset: 16)
                .bottom(to: self, offset: 50)
                .height(100)
        }
        contentView.makeConstraints {
            $0.horizontal(to: self, offset: 30)
                .center(in: self)
        }
    }
    
    // MARK: -
    private lazy var contentView: UIView = {
        let view = BottomTipsView()
        let controller = UIHostingController(rootView: view)
        controller.view.isUserInteractionEnabled = false
        controller.view.backgroundColor = .clear
        return controller.view
    }()
    
}
