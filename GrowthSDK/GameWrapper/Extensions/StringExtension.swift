//
//  StringExtension.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/31.
//

import SwiftUI

// MARK: -
extension String {
    
    var localized: LocalizedStringKey {
        return LocalizedStringKey(self)
    }
    
    var trimming: String {
        return trimmingCharacters(in: .whitespaces)
    }
    
    var encodUrl: String {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
}
