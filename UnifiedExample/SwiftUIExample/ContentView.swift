//
//  ContentView.swift
//  SwiftUIExample
//
//  Created by arvin on 2025/8/7.
//

import SwiftUI
import GrowthSDK

// MARK: -
struct ContentView: View {
    
    @State private var unityController: UIViewController?
    
    var body: some View {
        Group {
            if let controller = unityController {
                unityView(controller)
            } else {
                Color("launch")
            }
        }
        .ignoresSafeArea()
        .onAppear {
            initializeUnity()
        }
    }
    private func initializeUnity() {
        Task {
            do {
                let controller = try await UnityManager.shared.initializeUnity()
                self.unityController = controller
            } catch {
                print("[app] Unity初始化失败: \(error)")
            }
        }
    }
    
//    private func initializeUnity2() {
//        UnityManager.shared.initializeUnity { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let controller):
//                    self.unityController = controller
//                case .failure(let error):
//                    print("[app] Unity初始化失败: \(error)")
//                }
//            }
//        }
//    }
    
    // MARK: -
    private func unityView(_ controller: UIViewController) -> some View {
        GrowthKit.createView(with: controller)
            .ignoresSafeArea()
    }
    
}
