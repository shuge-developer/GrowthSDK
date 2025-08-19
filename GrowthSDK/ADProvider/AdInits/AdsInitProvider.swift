//
//  AdsInitProvider.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation

typealias AdInitComplete = ((AD) -> Void)

internal enum AD {
    case admob, bigo, kwai, max
    
    internal var description: String {
        switch self {
        case .admob:
            return "AdMob"
        case .bigo:
            return "Bigo"
        case .kwai:
            return "Kwai"
        case .max:
            return "Max"
        }
    }
}

// MARK: -
internal class AdsInitProvider {
    
    static var allInitialized: Bool {
        MaxAdProvider.shared.isInitialized  &&
        KwaiAdProvider.shared.isInitialized &&
        BigoAdProvider.shared.isInitialized &&
        AdMobProvider.shared.isInitialized
    }
    
    static var appOpenInitialized: Bool {
        AdMobProvider.shared.isInitialized
    }
    
    static var videoAdInitialized: Bool {
        MaxAdProvider.shared.isInitialized  &&
        KwaiAdProvider.shared.isInitialized &&
        BigoAdProvider.shared.isInitialized
    }
    
    // MARK: -
    static func startup(complete: AdInitComplete? = nil) {
        if !KwaiAdProvider.shared.isInitialized {
            KwaiAdProvider.shared.initialize(complete: complete)
        }
        if !MaxAdProvider.shared.isInitialized {
            MaxAdProvider.shared.initialize(complete: complete)
        }
        if !BigoAdProvider.shared.isInitialized {
            BigoAdProvider.shared.initialize(complete: complete)
        }
        if !AdMobProvider.shared.isInitialized {
            AdMobProvider.shared.initialize(complete: complete)
        }
    }
    
    // MARK: -
    static func showDebugger() {
        MaxAdProvider.shared.showDebugger()
    }
    
}
