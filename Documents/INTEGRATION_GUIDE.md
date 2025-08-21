# GrowthSDK Integration Guide

Complete step-by-step integration guide for iOS applications using GrowthSDK.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Basic Setup](#basic-setup)
4. [SDK Initialization](#sdk-initialization)
5. [Permission Configuration](#permission-configuration)
6. [Testing Integration](#testing-integration)

## 🔧 Prerequisites

Before integrating GrowthSDK, ensure you have:

- **Xcode 14.0+** with iOS 14.0+ deployment target
- **CocoaPods 1.10.0+** installed
- **iOS 14.0+** as minimum deployment target
- **Swift 5.0+** project (or mixed Objective-C/Swift)

## 📦 Installation

### Option 1: CocoaPods (Recommended)

1. **Add to Podfile**

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourAppTarget' do
  pod 'GrowthSDK', '~> 1.0.0'
end
```

2. **Install Dependencies**

```bash
pod repo update && pod install
```

3. **Open Workspace**

```bash
open YourApp.xcworkspace
```

### Option 2: Manual Integration

1. Download `GrowthSDK.xcframework`
2. Drag the framework into your Xcode project
3. Set "Embed & Sign" in "Frameworks, Libraries, and Embedded Content"
4. Ensure `Always Embed Swift Standard Libraries` is set to `Yes`

## ⚙️ Basic Setup

### Required Dependencies

Even with manual integration, you need these third-party SDKs:

```ruby
target 'YourAppTarget' do
  pod 'AppLovinSDK', '13.3.1'
  pod 'KwaiAdsSDK', '1.2.0'
end
```

### Optional Ad Mediation Adapters

For multi-platform advertising support:

```ruby
target 'YourAppTarget' do
  # Optional adapters (add as needed)
  pod 'AppLovinMediationBigoAdsAdapter', '4.9.3.0'
  pod 'AppLovinMediationByteDanceAdapter', '7.5.0.5.0'
  pod 'AppLovinMediationChartboostAdapter', '9.9.2.1'
  pod 'AppLovinMediationFyberAdapter', '8.3.8.0'
  pod 'AppLovinMediationGoogleAdapter', '12.9.0.0'
  pod 'AppLovinMediationInMobiAdapter', '10.8.6.0'
  pod 'AppLovinMediationVungleAdapter', '7.5.3.0'
  pod 'AppLovinMediationFacebookAdapter', '6.20.1.0'
  pod 'AppLovinMediationMintegralAdapter', '7.7.9.0.0'
  pod 'AppLovinMediationMolocoAdapter', '3.12.1.0'
end
```

## 🚀 SDK Initialization

### Swift Implementation

#### UIKit AppDelegate

```swift
import UIKit
import GrowthSDK

struct CustomNetworkConfig: NetworkConfigurable {
    let serviceId: String = "your_service_id"
    let bundleName: String = "com.example.app"
    let serviceUrl: String = "https://api.example.com"
    let publicKey: String = "your_public_key_pem"
    let serviceKey: String = "your_service_key"
    let serviceIv: String = "your_service_iv"
    var configKeyItems: [ConfigKeyItem]? {
        [
            ConfigKeyItem(adjustKey: "your_adjust_key"),
            ConfigKeyItem(configKey: "your_config_key"),
            ConfigKeyItem(adUnitKey: "your_adunit_key")
        ]
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Task {
            do {
                try await GrowthKit.shared.initialize(with: CustomNetworkConfig())
                print("SDK initialized successfully")
            } catch {
                print("SDK initialization failed: \(error)")
            }
        }
        return true
    }
}
```

#### SwiftUI App

```swift
import SwiftUI
import GrowthSDK
import UIKit

struct CustomNetworkConfig: NetworkConfigurable {
    let serviceId: String = "your_service_id"
    let bundleName: String = "com.example.app"
    let serviceUrl: String = "https://api.example.com"
    let publicKey: String = "your_public_key_pem"
    let serviceKey: String = "your_service_key"
    let serviceIv: String = "your_service_iv"
    var configKeyItems: [ConfigKeyItem]? {
        [
            ConfigKeyItem(adjustKey: "your_adjust_key"),
            ConfigKeyItem(configKey: "your_config_key"),
            ConfigKeyItem(adUnitKey: "your_adunit_key")
        ]
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Task {
            do {
                try await GrowthKit.shared.initialize(with: CustomNetworkConfig())
                print("SDK initialized successfully")
            } catch {
                print("SDK initialization failed: \(error)")
            }
        }
        return true
    }
}

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Objective-C Implementation

```objective-c
// AppDelegate.m
#import <GrowthSDK/GrowthSDK-Swift.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initializeGrowthKitSDK:launchOptions];
    return YES;
}

- (void)initializeGrowthKitSDK:(NSDictionary *)launchOptions {
    NSArray<ConfigKeyItem *> *configKeys = @[
        [[ConfigKeyItem alloc] initWithAdjustKey:@"your_adjust_key"],
        [[ConfigKeyItem alloc] initWithConfigKey:@"your_config_key"],
        [[ConfigKeyItem alloc] initWithAdUnitKey:@"your_adunit_key"]
    ];

    NetworkConfig *config = [[NetworkConfig alloc] initWithServiceId:@"your_service_id"
                                                         bundleName:@"com.example.app"
                                                         serviceUrl:@"https://api.example.com"
                                                         serviceKey:@"your_service_key"
                                                          serviceIv:@"your_service_iv"
                                                          publicKey:@"your_public_key_pem"
                                                     configKeyItems:configKeys
                                                              other:nil];

    [[GrowthKit shared] initializeWith:config launchOptions:launchOptions completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"SDK initialization failed: %@", error.localizedDescription);
            } else {
                NSLog(@"SDK initialized successfully");
            }
        });
    }];
}
```

## 🔐 Permission Configuration

### Info.plist Requirements

#### 1. HTTP Requests (Required)

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

#### 2. App Tracking Transparency (Required)

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use your device identifier for advertising optimization and attribution analysis.</string>
```

#### 3. AdMob App ID (Required)

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

#### 4. SKAdNetwork (Required)

Add the complete SKAdNetworkItems array from the [Requirements Guide](REQUIREMENTS.md#skadnetwork-configuration).

#### 5. AppDelegate Window Property (Required for Ad Mediation)

If using ad mediation adapters, ensure your AppDelegate exposes a readable `window` property:

```swift
var window: UIWindow?
```

## 🧪 Testing Integration

### 1. Check Initialization Status

```swift
// Check if SDK is ready
let isReady = GrowthKit.shared.isInitialized

// Check current state
let state = GrowthKit.shared.state
// InitState.uninitialized  - Not initialized
// InitState.initializing   - Initializing  
// InitState.initialized    - Initialized
// InitState.failed         - Initialization failed
```

### 2. Test Basic Functionality

```swift
// Test ad display
GrowthKit.showAd(with: .rewarded)

// Test debug panel
GrowthKit.shared.showAdDebugger()
```

### 3. Enable Logging

```swift
// Enable SDK logging
GrowthKit.isLoggingEnabled = true
```

## 🔍 Troubleshooting

### Common Issues

1. **Build Errors**
   - Ensure `Always Embed Swift Standard Libraries` is set to `Yes`
   - Check that all required frameworks are properly linked

2. **Runtime Crashes**
   - Verify AdMob App ID is correctly set in Info.plist
   - Ensure all required permissions are configured

3. **Initialization Failures**
   - Check network connectivity
   - Verify configuration parameters
   - Review console logs for specific error messages

### Debug Tips

- Enable SDK logging: `GrowthKit.isLoggingEnabled = true`
- Use the debug panel: `GrowthKit.shared.showAdDebugger()`
- Check initialization state: `GrowthKit.shared.state`

## 📱 Next Steps

After successful integration:

1. [Configure Advertising](ADVERTISING_GUIDE.md) - Set up ad formats and networks
2. [Unity Integration](UNITY_INTEGRATION_GUIDE.md) - For game developers
3. [Advanced Features](ADVANCED_FEATURES.md) - Explore advanced capabilities
4. [Testing Guide](TESTING_GUIDE.md) - Comprehensive testing strategies

## 📞 Support

If you encounter issues during integration:

- Check the [FAQ](FAQ.md) for common solutions
- Review [Requirements](REQUIREMENTS.md) for configuration details
- Contact support: [support@shuge.com](mailto:support@shuge.com)
- Report issues: [GitHub Issues](https://github.com/shuge-developer/GrowthSDK/issues)

---

**Need help?** Check our [FAQ](FAQ.md) or [contact support](mailto:support@shuge.com).
