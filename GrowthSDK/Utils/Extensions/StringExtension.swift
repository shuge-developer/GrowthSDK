//
//  StringExtension.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/31.
//

import Foundation
import SwiftUI

// MARK: - SDK Resource Bundle
internal enum SDKStringBundleProvider {
    static var bundle: Bundle { SDKResourceBundle.bundle }
}

// MARK: -
internal extension String {
    
    var localized: LocalizedStringKey {
        return LocalizedStringKey(self)
    }
    
    var trimming: String {
        return trimmingCharacters(in: .whitespaces)
    }
    
    var encodUrl: String {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
    func localized(_ args: CVarArg...) -> String {
        let bundle = SDKStringBundleProvider.bundle
        let sdkString = NSLocalizedString(self, tableName: "GrowthSDK", bundle: bundle, value: self, comment: "")
        let appString = NSLocalizedString(self, tableName: "GrowthSDK", bundle: .main, value: "", comment: "")
        let formatted = appString.isEmpty ? sdkString : appString
        return String(format: formatted, arguments: args)
    }
    
}
