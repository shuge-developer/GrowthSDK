//
//  AdPresentationWindow.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/19.
//

import Foundation
import UIKit

// MARK: -
@MainActor
internal final class AdWindowManager {
    static let shared = AdWindowManager()
    
    private var window: UIWindow?
    private let backgroundColor: UIColor = .clear
    private var showRetainCounter: Int = 0
    private var pendingCleanup: DispatchWorkItem?
    private var isPresenting: Bool = false
    
    private init() {}
    
    // MARK: -
    internal func beginPresentation() -> UIViewController? {
        guard !isPresenting else { return nil }
        let rootVC = getRootViewController()
        isPresenting = true
        return rootVC
    }
    
    internal func endPresentation() {
        isPresenting = false
        releaseWindow()
    }
    
    // MARK: -
    private func getRootViewController() -> UIViewController {
        let rootVC = window!.rootViewController!
        showRetainCounter += 1
        ensureWindowVisible()
        return rootVC
    }
    
    private func releaseWindow() {
        showRetainCounter = max(0, showRetainCounter - 1)
        if showRetainCounter == 0 {
            hideAndCleanupWindow()
        }
    }
    
    // MARK: -
    private func getActiveScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first { $0.activationState == .foregroundActive }
        return activeScene ?? scenes.first
    }
    
    private func ensureWindowVisible() {
        pendingCleanup?.cancel()
        pendingCleanup = nil
        if window == nil {
            let rootVC = UIViewController()
            rootVC.view.backgroundColor = backgroundColor
            if let activeScene = getActiveScene() {
                let win = UIWindow(windowScene: activeScene)
                win.frame = UIScreen.main.bounds
                win.windowLevel = .alert + 1000
                win.backgroundColor = backgroundColor
                win.rootViewController = rootVC
                win.isHidden = false
                win.makeKeyAndVisible()
                window = win
            } else {
                let win = UIWindow(frame: UIScreen.main.bounds)
                win.windowLevel = .alert + 1000
                win.backgroundColor = backgroundColor
                win.rootViewController = rootVC
                win.isHidden = false
                win.makeKeyAndVisible()
                window = win
            }
        } else {
            window?.isHidden = false
            window?.makeKeyAndVisible()
        }
    }
    
    private func hideAndCleanupWindow() {
        guard let win = window else { return }
        win.isHidden = true
        
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.window?.rootViewController = nil
            self.window = nil
        }
        pendingCleanup = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.2, execute: work
        )
    }
    
}
