//
//  AppDelegate.swift
//  SwiftExample
//
//  Created by arvin on 2025/8/7.
//

import UIKit
import GrowthSDK

// MARK: -
struct CustomNetworkConfig: NetworkConfigurable {
    let serviceId: String = "1937764714536771585"
    let bundleName: String = "com.shuge.game.tongyong"
    let serviceUrl: String = "http://lj309075ba9.vicp.fun"
    let publicKey: String = """
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAk7vrn
    UKeb6Ky1h/rigkTWQzSURT8hGL6YujadShx3aL3WmfAR6DvSW
    HslkbIjbRUJWvZTrIHMB8slooq1LEDp28eWzGjK1C95bVX/S6
    GyisONAAd1vseRBi/BTQQFkanskLDxjfzl+bkGBpd59xfr16z
    ys9MbvcuN3zzEy9v56xZYXWn6r6Aca7+afBsH4hQc3Deo95bm
    2Q6EVM2l1OLOAX2GWqqtslICY/h8EZSCtFWs4e8r/BR+/bcYt
    TOu+D43gNDZ5IBjwcTtFhrxbOKda/g8w6nbXGAECErEY4+Udh
    71VEW/N2N88vbwq7b8CGC7/GsPsyRs+5uTV2md4GJeQIDAQAB
    """
    let serviceKey: String = "VIZFwZVGXUuefGUV"
    let serviceIv: String = "YjPBSAtcLZghUVEq"
    var configKeyItems: [ConfigKeyItem]? {
        [
            ConfigKeyItem(adjustKey: "ccs_ad_just_config"),
            ConfigKeyItem(configKey: "ccs_sdk_config"),
            ConfigKeyItem(adUnitKey: "ccs_ad_config")
        ]
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initializeGrowthKitSDK()
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: -
    private func initializeGrowthKitSDK() {
        Task {
            do {
                let config = CustomNetworkConfig()
                try await GrowthKit.shared.initialize(with: config)
                print("[app] SDK初始化成功")
            } catch {
                print("[app] SDK初始化失败: \(error)")
            }
        }
    }
    
}
