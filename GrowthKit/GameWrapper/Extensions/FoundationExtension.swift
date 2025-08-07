//
//  FoundationExtension.swift
//  GrowthKit
//
//  Created by arvin on 2025/7/31.
//

import Foundation

// MARK: -
extension CGSize {
    var isZero: Bool {
        return width <= 0 && height <= 0
    }
}

extension CGPoint {
    var isZero: Bool {
        return x <= 0 && y <= 0
    }
}

