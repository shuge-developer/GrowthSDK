//
//  UnityCallProvider.swift
//  SwiftExample
//
//  Created by arvin on 2025/8/21.
//

import Foundation
import GrowthSDK

// MARK: -
class UnityCallProvider: NativeCallable {
    
    static let shared = UnityCallProvider()
    
    // MARK: - NativeCallable
    func onAdShow(_ json: String?) {
        guard let json else { return }
        switch json {
        case "0":
            GrowthKit.showAd(with: .rewarded)
        case "1":
            GrowthKit.showAd(with: .inserted)
        case "2":
            GrowthKit.showAd(with: .appOpen)
        case "3":
            GrowthKit.shared.showAdDebugger()
        default:
            break
        }
    }
    
}
