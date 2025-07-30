//
//  DispatchQueueExtension.swift
//  GameWrapper
//
//  Created by arvin on 2025/7/28.
//

import Foundation

// MARK: -
internal extension DispatchQueue {
    
    static func mainAsyncAfter(_ delay: TimeInterval, execute work: @escaping @convention(block) () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
}
