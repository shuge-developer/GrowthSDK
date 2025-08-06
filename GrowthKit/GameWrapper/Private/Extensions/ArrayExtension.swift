//
//  ArrayExtension.swift
//  GrowthKit
//
//  Created by arvin on 2025/7/28.
//

import Foundation

// MARK: -
internal extension Array where Element: CustomStringConvertible {
    
    func separator(_ str: String = ",") -> String {
        let map = self.map { $0.description }
        return map.joined(separator: str)
    }
    
}
