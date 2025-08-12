//
//  Locale+Language.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/20.
//

import Foundation

// MARK: -
extension NSLocale {
    
    internal static var preferredShortLanguage: String {
        return parser(preferredLanguages).first ?? ""
    }
    
    internal static func parser(_ languages: [String]) -> [String] {
        let languages = languages.map { element in
            let components1 = element.components(separatedBy: "-")
            if components1.count > 1 { return components1[0] }
            
            let components2 = element.components(separatedBy: "_")
            if components2.count > 1 { return components2[0] }
            return element
        }
        return languages
    }
}
