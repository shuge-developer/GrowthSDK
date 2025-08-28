//
//  UnityManager.swift
//  ObjcExample
//
//  Created by arvin on 2025/8/7.
//

import Foundation
import UnityFramework
import Combine
import UIKit

// MARK: -
enum UnityError: Error, LocalizedError {
    case frameworkNotFound
    case notInitialized
    case controllerNotFound
    case viewNotFound
    
    var errorDescription: String? {
        switch self {
        case .frameworkNotFound:
            return "Unity Framework未找到，请确保Unity Framework已正确链接"
        case .notInitialized:
            return "Unity Framework未初始化"
        case .controllerNotFound:
            return "Unity视图控制器未找到"
        case .viewNotFound:
            return "Unity视图未找到"
        }
    }
    
    var errorCode: Int {
        switch self {
        case .frameworkNotFound:
            return -1001
        case .notInitialized:
            return -1002
        case .controllerNotFound:
            return -1003
        case .viewNotFound:
            return -1004
        }
    }
    
    var nsError: NSError {
        let info = [NSLocalizedDescriptionKey: errorDescription ?? "未知错误"]
        return NSError(domain: "UnityManager", code: errorCode, userInfo: info)
    }
}

// MARK: -
@objcMembers
public class UnityMessage: NSObject {
    public let obj: String?
    public let method: String?
    public let msg: String?
    
    public init(obj: String?, method: String?, msg: String? = nil) {
        self.obj = obj
        self.method = method
        self.msg = msg
        super.init()
    }
}

// MARK: -
@objcMembers
public class UnityManager: NSObject {
    
    // MARK: -
    public static let shared = UnityManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    private var unityFramework: UnityFramework?
    private var unityDelegate: UnityAppController? {
        return unityFramework?.appController()
    }
    
    public private(set) var isInitialized: Bool = false
    public private(set) var unityController: UIViewController?
    public private(set) var unityView: UIView?
    
    // MARK: -
    private override init() {
        super.init()
        unityFramework = loadFramework()
        setupNotificationObservers()
    }
    
    // MARK: -
    /// 初始化Unity
    public func initializeUnity() async throws -> UIViewController {
        return try await withCheckedThrowingContinuation { continuation in
            initializeUnity { result in
                switch result {
                case .success(let controller):
                    continuation.resume(returning: controller)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 初始化Unity
    /// - Parameter completion: 完成回调，返回Result类型
    public func initializeUnity(_ completion: @escaping (Result<UIViewController, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard !isInitialized else {
                guard let controller = unityController else {
                    completion(.failure(UnityError.notInitialized))
                    return
                }
                completion(.success(controller))
                return
            }
            
            guard let framework = unityFramework else {
                completion(.failure(UnityError.frameworkNotFound))
                return
            }
            
            framework.runEmbedded(withArgc: CommandLine.argc,
                                  argv: CommandLine.unsafeArgv,
                                  appLaunchOpts: nil)
            
            FrameworkLibAPI.register(UnityCallProvider.shared)
            
            guard let controller = unityDelegate?.rootViewController else {
                completion(.failure(UnityError.controllerNotFound))
                return
            }
            self.unityController = controller
            
            guard let unityView = unityDelegate?.rootView else {
                completion(.failure(UnityError.viewNotFound))
                return
            }
            self.unityView = unityView
            
            handleUnityWindows()
            isInitialized = true
            
            completion(.success(controller))
        }
    }
    
    /// 初始化Unity
    /// - Parameter completion: 完成回调，返回UIViewController和NSError
    @objc public func initializeUnity(_ completion: @escaping (UIViewController?, NSError?) -> Void) {
        initializeUnity { result in
            switch result {
            case .success(let controller):
                completion(controller, nil)
                
            case .failure(let error):
                if let unityError = error as? UnityError {
                    completion(nil, unityError.nsError)
                } else {
                    completion(nil, error as NSError)
                }
            }
        }
    }
    
    /// 发送消息到Unity
    /// - Parameter message: Unity消息对象
    @objc public func sendMessage(_ message: UnityMessage) {
        guard let framework = unityFramework, isInitialized else {
            print("[UnityManager] Unity未初始化，无法发送消息")
            return
        }
        framework.sendMessageToGO(
            withName: message.obj ?? "",
            functionName: message.method ?? "",
            message: message.msg ?? ""
        )
    }
    
    // MARK: -
    /// 加载Unity Framework
    private func loadFramework() -> UnityFramework? {
        let path = "/Frameworks/UnityFramework.framework"
        let bundlePath = Bundle.main.bundlePath + path
        
        guard let bundle = Bundle(path: bundlePath) else {
            return nil
        }
        
        if !bundle.isLoaded {
            bundle.load()
        }
        
        guard let unityFramework = bundle.principalClass?.getInstance() else {
            return nil
        }
        
        if unityFramework.appController() == nil {
            let machineHeader = #dsohandle.assumingMemoryBound(to: MachHeader.self)
            unityFramework.setExecuteHeader(machineHeader)
        }
        
        unityFramework.setDataBundleId("com.unity3d.framework")
        unityFramework.register(self)
        return unityFramework
    }
    
    /// 处理Unity窗口
    private func handleUnityWindows() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let windows = UIApplication.keyWindows
            for (index, window) in windows.enumerated() {
                if index > 0 { window.isHidden = true }
            }
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: -
private extension UnityManager {
    
    /// 设置通知观察者
    func setupNotificationObservers() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.applicationWillResignActive()
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.applicationDidBecomeActive()
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.applicationDidEnterBackground()
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.applicationWillEnterForeground()
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.applicationWillTerminate()
            }
            .store(in: &cancellables)
    }
    
    /// 应用进入后台
    func applicationDidEnterBackground() {
        guard let delegate = unityDelegate else { return }
        delegate.applicationDidEnterBackground(.shared)
    }
    
    /// 应用即将进入前台
    func applicationWillEnterForeground() {
        guard let delegate = unityDelegate else { return }
        delegate.applicationWillEnterForeground(.shared)
    }
    
    /// 应用变为活跃状态
    func applicationDidBecomeActive() {
        guard let delegate = unityDelegate else { return }
        delegate.applicationDidBecomeActive(.shared)
    }
    
    /// 应用即将失去活跃状态
    func applicationWillResignActive() {
        guard let delegate = unityDelegate else { return }
        delegate.applicationWillResignActive(.shared)
    }
    
    /// 应用即将终止
    func applicationWillTerminate() {
        guard let delegate = unityDelegate else { return }
        delegate.applicationWillTerminate(.shared)
    }
}

// MARK: -
extension UnityManager: UnityFrameworkListener {
    
    /// Unity卸载回调
    private func unityDidUnload(_ notification: NSNotification!) {
        print("[UnityManager] Unity已卸载")
    }
    
    /// Unity退出回调
    private func unityDidQuit(_ notification: NSNotification!) {
        print("[UnityManager] Unity已退出")
    }
}

// MARK: -
private extension UIApplication {
    
    /// 获取当前活跃窗口
    static var keyWindows: [UIWindow] {
        if #available(iOS 13.0, *) {
            let windows = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }.first?.windows
            return windows ?? []
        } else {
            return UIApplication.shared.windows
        }
    }
}

