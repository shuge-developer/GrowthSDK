# GrowthSDK API Reference

Complete API documentation with examples and usage patterns for GrowthSDK.

## 📋 Table of Contents

1. [Core Classes](#core-classes)
2. [Initialization](#initialization)
3. [Advertising APIs](#advertising-apis)
4. [Configuration](#configuration)
5. [View Management](#view-management)
6. [Utilities](#utilities)
7. [Error Handling](#error-handling)
8. [Protocols](#protocols)

## 🏗️ Core Classes

### GrowthKit

Main entry point for GrowthSDK functionality.

```swift
@objc public class GrowthKit: NSObject
```

#### Properties

```swift
// Shared instance
@objc public static var shared: GrowthKit { get }

// SDK version
@objc public static var sdkVersion: String { get }

// Logging control
@objc public static var isLoggingEnabled: Bool { get set }

// Initialization status
@objc public var isInitialized: Bool { get }

// Current state
@objc public var state: InitState { get }
```

#### Methods

```swift
// Initialization
@objc public func initialize(with config: NetworkConfig) async throws
@objc public func initialize(with config: NetworkConfig, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) async throws
@objc public func initialize(with config: NetworkConfig, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, completion: @escaping (Error?) -> Void)

// Ad display
@objc public static func showAd(with style: ADStyle)
@objc public static func showAd(with style: ADStyle, callbacks: AdCallbacks?)
@objc public func showAd(with style: ADStyle)
@objc public func showAd(with style: ADStyle, callbacks: AdCallbacks?)

// Ad management
@objc public func reloadAppOpenAd()
@objc public func reloadBiddingAd()

// Debug
@objc public func showAdDebugger()

// View creation
@objc public static func createController(with unityController: UIViewController?) -> UIViewController
@objc public static func createView(with unityController: UIViewController?) -> UIView
```

## 🚀 Initialization

### NetworkConfig

Configuration structure for SDK initialization.

```swift
@objc public struct NetworkConfig: NSObject
```

#### Properties

```swift
let serviceId: String                    // Service/Application ID
let bundleName: String                   // Bundle identifier
let serviceUrl: String                   // Base service URL
let serviceKey: String                   // Service encryption key
let serviceIv: String                    // Service initialization vector
let publicKey: String                    // Public key (PEM format)
let configKeyItems: [ConfigKeyItem]?     // Configuration keys
let other: OtherConfig?                  // Additional options
```

#### Initializers

```swift
// Swift initializer
public init(serviceId: String, bundleName: String, serviceUrl: String, serviceKey: String, serviceIv: String, publicKey: String, configKeyItems: [ConfigKeyItem]?, other: OtherConfig?)

// Objective-C initializer
@objc public init(serviceId: String, bundleName: String, serviceUrl: String, serviceKey: String, serviceIv: String, publicKey: String, configKeyItems: [ConfigKeyItem]?, other: OtherConfig?)
```

#### Usage Examples

```swift
// Basic configuration
let config = NetworkConfig(
    serviceId: "my_app",
    bundleName: Bundle.main.bundleIdentifier ?? "",
    serviceUrl: "https://api.example.com",
    serviceKey: "your_key",
    serviceIv: "your_iv",
    publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----",
    configKeyItems: nil,
    other: nil
)

// Advanced configuration
let configKeys = [
    ConfigKeyItem(configKey: "main_config"),
    ConfigKeyItem(adjustKey: "analytics_key"),
    ConfigKeyItem(adUnitKey: "ads_config")
]

let otherConfig = OtherConfig(
    thirdId: "partner_id",
    instanceId: "main_instance",
    campaign: "launch_2024",
    referer: "app_store",
    adid: "ad_network_id"
)

let advancedConfig = NetworkConfig(
    serviceId: "premium_app",
    bundleName: Bundle.main.bundleIdentifier ?? "",
    serviceUrl: "https://api.premium.com",
    serviceKey: "premium_key",
    serviceIv: "premium_iv",
    publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----",
    configKeyItems: configKeys,
    other: otherConfig
)
```

### ConfigKeyItem

Configuration key structure for dynamic SDK behavior.

```swift
@objc public struct ConfigKeyItem: NSObject
```

#### Properties

```swift
let configKey: String?    // General configuration key
let adjustKey: String?    // Adjust analytics key
let adUnitKey: String?    // Ad unit configuration key
```

#### Initializers

```swift
// Swift initializers
public init(configKey: String?)
public init(adjustKey: String?)
public init(adUnitKey: String?)

// Objective-C initializers
@objc public init(configKey: String?)
@objc public init(adjustKey: String?)
@objc public init(adUnitKey: String?)
```

### OtherConfig

Additional configuration options for extended functionality.

```swift
@objc public struct OtherConfig: NSObject
```

#### Properties

```swift
let thirdId: String?      // Third-party identifier
let instanceId: String?   // Instance identifier
let campaign: String?     // Campaign identifier
let referer: String?      // Referrer information
let adid: String?         // Advertising identifier
```

#### Initializer

```swift
@objc public init(thirdId: String?, instanceId: String?, campaign: String?, referer: String?, adid: String?)
```

## 📱 Advertising APIs

### ADStyle

Enumeration of supported ad formats.

```swift
@objc public enum ADStyle: Int
```

#### Cases

```swift
case rewarded = 0   // Rewarded video ads
case inserted = 1   // Interstitial ads
case appOpen = 2    // App open ads
```

#### Internal Properties

```swift
internal var name: String  // Human-readable name
```

#### Usage Examples

```swift
// Show different ad types
GrowthKit.showAd(with: .rewarded)
GrowthKit.showAd(with: .inserted)
GrowthKit.showAd(with: .appOpen)

// Check ad type
switch adStyle {
case .rewarded:
    print("Rewarded ad")
case .inserted:
    print("Interstitial ad")
case .appOpen:
    print("App open ad")
}

// Get ad name
let adName = ADStyle.rewarded.name  // "rewarded"
```

### AdCallbacks

Protocol for handling ad lifecycle events.

```swift
@objc public protocol AdCallbacks: NSObjectProtocol
```

#### Methods

```swift
// Loading events
@objc optional func onStartLoading(_ style: ADStyle)
@objc optional func onLoadSuccess(_ style: ADStyle)
@objc optional func onLoadFailed(_ style: ADStyle, error: Error?)

// Display events
@objc optional func onShowSuccess(_ style: ADStyle)
@objc optional func onShowFailed(_ style: ADStyle, error: Error?)

// User interaction events
@objc optional func onGetAdReward(_ style: ADStyle)
@objc optional func onAdClick(_ style: ADStyle)
@objc optional func onAdClose(_ style: ADStyle)
```

#### Implementation Example

```swift
class AdManager: NSObject, AdCallbacks {
    
    func showAd(_ style: ADStyle) {
        GrowthKit.showAd(with: style, callbacks: self)
    }
}

// MARK: - AdCallbacks
extension AdManager {
    
    func onStartLoading(_ style: ADStyle) {
        print("Ad loading started: \(style.name)")
        // Show loading indicator
    }
    
    func onLoadSuccess(_ style: ADStyle) {
        print("Ad loaded successfully: \(style.name)")
        // Hide loading indicator
    }
    
    func onLoadFailed(_ style: ADStyle, error: Error?) {
        print("Ad load failed: \(style.name), error: \(error?.localizedDescription ?? "Unknown")")
        // Handle load failure
    }
    
    func onShowSuccess(_ style: ADStyle) {
        print("Ad shown successfully: \(style.name)")
        // Track ad impression
    }
    
    func onShowFailed(_ style: ADStyle, error: Error?) {
        print("Ad show failed: \(style.name), error: \(error?.localizedDescription ?? "Unknown")")
        // Handle show failure
    }
    
    func onGetAdReward(_ style: ADStyle) {
        print("User earned reward from: \(style.name)")
        // Grant user reward
    }
    
    func onAdClick(_ style: ADStyle) {
        print("Ad clicked: \(style.name)")
        // Track ad click
    }
    
    func onAdClose(_ style: ADStyle) {
        print("Ad closed: \(style.name)")
        // Resume game/app
    }
}
```

## ⚙️ Configuration

### NetworkConfigurable

Protocol for custom configuration implementations.

```swift
public protocol NetworkConfigurable
```

#### Required Properties

```swift
var serviceId: String { get }
var bundleName: String { get }
var serviceUrl: String { get }
var publicKey: String { get }
var serviceKey: String { get }
var serviceIv: String { get }
var configKeyItems: [ConfigKeyItem]? { get }
```

#### Implementation Example

```swift
struct CustomNetworkConfig: NetworkConfigurable {
    let serviceId: String = "custom_app"
    let bundleName: String = Bundle.main.bundleIdentifier ?? ""
    let serviceUrl: String = "https://api.custom.com"
    let publicKey: String = "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
    let serviceKey: String = "custom_key"
    let serviceIv: String = "custom_iv"
    var configKeyItems: [ConfigKeyItem]? {
        [
            ConfigKeyItem(configKey: "custom_config"),
            ConfigKeyItem(adjustKey: "custom_analytics")
        ]
    }
}

// Usage
let config = CustomNetworkConfig()
try await GrowthKit.shared.initialize(with: config)
```

## 🖼️ View Management

### Controller Creation

```swift
// Create SDK view controller
let sdkController = GrowthKit.createController(with: unityController)

// Present controller
present(sdkController, animated: true)
```

### View Creation

```swift
// Create SDK view
let sdkView = GrowthKit.createView(with: unityController)

// Add to view hierarchy
view.addSubview(sdkView)
```

## 🛠️ Utilities

### Logger

Internal logging utility for SDK debugging.

```swift
internal enum Logger
```

#### Methods

```swift
static func info(_ message: String)
static func warning(_ message: String)
static func error(_ message: String)
```

### Device

Device information utilities.

```swift
internal struct Device
```

#### Properties

```swift
static var identifier: String
static var model: String
static var systemVersion: String
static var appVersion: String
static var buildNumber: String
```

## ❌ Error Handling

### InitError

Errors that can occur during SDK initialization.

```swift
@objc public enum InitError: Error, LocalizedError
```

#### Cases

```swift
case alreadyInitialized
case storageInitFailed(String)
case serviceInitFailed(String)
```

#### Properties

```swift
var errorDescription: String? { get }
var failureReason: String? { get }
```

#### Usage Example

```swift
do {
    try await GrowthKit.shared.initialize(with: config)
    print("SDK initialized successfully")
} catch let error as InitError {
    switch error {
    case .alreadyInitialized:
        print("SDK already initialized")
    case .storageInitFailed(let message):
        print("Storage initialization failed: \(message)")
    case .serviceInitFailed(let message):
        print("Service initialization failed: \(message)")
    }
} catch {
    print("Unknown error: \(error)")
}
```

### AdError

Errors that can occur during ad operations.

```swift
@objc public enum AdError: Error, LocalizedError
```

#### Cases

```swift
case noFill
case networkError
case timeout
case invalidConfiguration
```

## 🔌 Protocols

### NativeCallable

Protocol for Unity integration bridge.

```swift
@objc public protocol NativeCallable: NSObjectProtocol
```

#### Methods

```swift
@objc func onAdShow(_ json: String?)
```

#### Implementation Example

```objc
@interface UnityCallProvider : NSObject<NativeCallable>
@end

@implementation UnityCallProvider

- (void)onAdShow:(nullable NSString *)json {
    NSInteger showType = [json integerValue];
    switch (showType) {
        case 0:
            [GrowthKit showAdWith:ADStyleRewarded];
            break;
        case 1:
            [GrowthKit showAdWith:ADStyleInserted];
            break;
        case 2:
            [GrowthKit showAdWith:ADStyleAppOpen];
            break;
        case 3:
            [[GrowthKit shared] showAdDebugger];
            break;
        default:
            break;
    }
}

@end
```

## 📱 Platform-Specific APIs

### iOS-Specific

```swift
// iOS-specific initialization
@objc public func initialize(with config: NetworkConfig, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) async throws

// iOS-specific view creation
@objc public static func createController(with unityController: UIViewController?) -> UIViewController
@objc public static func createView(with unityController: UIViewController?) -> UIView
```

### Unity Integration

```swift
// Unity-specific view management
@objc public static func createController(with unityController: UIViewController?) -> UIViewController
@objc public static func createView(with unityController: UIViewController?) -> UIView
```

## 🔍 Debugging APIs

### Debug Panel

```swift
// Show debug panel
@objc public func showAdDebugger()
```

### Logging Control

```swift
// Enable/disable logging
@objc public static var isLoggingEnabled: Bool { get set }
```

### Status Checking

```swift
// Check initialization status
@objc public var isInitialized: Bool { get }

// Check current state
@objc public var state: InitState { get }
```

## 📊 Performance APIs

### Ad Preloading

```swift
// Preload app open ads
@objc public func reloadAppOpenAd()

// Preload bidding ads
@objc public func reloadBiddingAd()
```

### Background Operations

```swift
// Background ad loading
Task { @MainActor in
    await AppOpenAdManager.shared.loadAd()
}
```

## 🔒 Security APIs

### Encryption

```swift
// Service key encryption
let serviceKey: String

// Service IV
let serviceIv: String

// Public key verification
let publicKey: String
```

### Secure Storage

```swift
// Internal secure storage
internal let secureStorage: SecureStorage
```

## 📱 Lifecycle Management

### App Lifecycle

```swift
// App launch
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool

// App foreground
func applicationWillEnterForeground(_ application: UIApplication)

// App background
func applicationDidEnterBackground(_ application: UIApplication)
```

### SDK Lifecycle

```swift
// Initialize
try await GrowthKit.shared.initialize(with: config)

// Check status
let isReady = GrowthKit.shared.isInitialized
let state = GrowthKit.shared.state

// Cleanup (automatic)
// SDK automatically handles cleanup on app termination
```

## 📞 Support

For API-related questions:

- Check the [Integration Guide](INTEGRATION_GUIDE.md)
- Review [Configuration Guide](CONFIGURATION_GUIDE.md)
- Contact support: [support@shuge.com](mailto:support@shuge.com)

---

**Need help with the API?** Check our [FAQ](FAQ.md) or [contact support](mailto:support@shuge.com).
