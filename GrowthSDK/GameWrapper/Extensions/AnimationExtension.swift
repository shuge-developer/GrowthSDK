//
//  AnimationExtension.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/31.
//

import SwiftUI

@discardableResult
func _animation<Result>(_ animation: Animation? = .default, _ duration: TimeInterval = 0.25, _ body: () throws -> Result, completion: (() -> Void)? = nil) rethrows -> Result {
    if #available(iOS 17.0, *) {
        return try withAnimation(animation, body) {
            completion?()
        }
    } else {
        DispatchQueue.mainAsyncAfter(duration) {
            completion?()
        }
        return try withAnimation(animation, body)
    }
}
