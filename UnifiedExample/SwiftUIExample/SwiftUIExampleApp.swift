//
//  SwiftUIExampleApp.swift
//  SwiftUIExample
//
//  Created by arvin on 2025/8/7.
//

import SwiftUI

@main
struct SwiftUIExampleApp: App {
    
    @UIApplicationDelegateAdaptor private var delegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
