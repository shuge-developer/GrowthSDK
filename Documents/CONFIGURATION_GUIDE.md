# GrowthSDK Configuration Guide

Comprehensive configuration guide for GrowthSDK, including all available options and best practices.

## 📋 Table of Contents

1. [Configuration Overview](#configuration-overview)
2. [Network Configuration](#network-configuration)
3. [Configuration Keys](#configuration-keys)
4. [Other Configuration Options](#other-configuration-options)
5. [Best Practices](#best-practices)
6. [Configuration Examples](#configuration-examples)

## 🔧 Configuration Overview

GrowthSDK uses a centralized configuration system through `NetworkConfig` that handles:

- **Service Configuration** - API endpoints and authentication
- **Security Settings** - Encryption keys and certificates
- **Feature Flags** - Optional SDK capabilities
- **Integration Keys** - Third-party service configurations

## 🌐 Network Configuration

### Core Configuration Parameters

```swift
struct NetworkConfig {
    let serviceId: String        // Service/Application ID
    let bundleName: String       // Bundle identifier
    let serviceUrl: String       // Base service URL
    let serviceKey: String       // Service encryption key
    let serviceIv: String        // Service initialization vector
    let publicKey: String        // Public key (PEM format)
    let configKeyItems: [ConfigKeyItem]?  // Configuration keys
    let other: OtherConfig?      // Additional options
}
```

### Parameter Descriptions

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `serviceId` | String | ✅ | Unique identifier for your service/application |
| `bundleName` | String | ✅ | Usually `Bundle.main.bundleIdentifier` |
| `serviceUrl` | String | ✅ | Base URL for SDK services (HTTPS recommended) |
| `serviceKey` | String | ✅ | Encryption key for secure communication |
| `serviceIv` | String | ✅ | Initialization vector for encryption |
| `publicKey` | String | ✅ | Public key in PEM format for verification |
| `configKeyItems` | Array | ❌ | Structured configuration keys |
| `other` | OtherConfig | ❌ | Additional configuration options |

## 🔑 Configuration Keys

### ConfigKeyItem Structure

```swift
struct ConfigKeyItem {
    let configKey: String?      // General configuration key
    let adjustKey: String?      // Adjust analytics key
    let adUnitKey: String?      // Ad unit configuration key
}
```

### Usage Examples

```swift
// Basic configuration key
let configKey = ConfigKeyItem(configKey: "your_config_key")

// Adjust analytics integration
let adjustKey = ConfigKeyItem(adjustKey: "your_adjust_key")

// Ad unit configuration
let adUnitKey = ConfigKeyItem(adUnitKey: "your_adunit_key")

// Multiple keys
let configKeys: [ConfigKeyItem] = [
    ConfigKeyItem(configKey: "main_config"),
    ConfigKeyItem(adjustKey: "analytics_key"),
    ConfigKeyItem(adUnitKey: "rewarded_video")
]
```

### Key Management

Configuration keys drive SDK behavior:

- **Dynamic Configuration** - Server-driven settings
- **Feature Toggles** - Enable/disable specific features
- **A/B Testing** - Different configurations for user segments
- **Environment Switching** - Dev/Staging/Production configurations

## ⚙️ Other Configuration Options

### OtherConfig Structure

```swift
struct OtherConfig {
    let thirdId: String?        // Third-party identifier
    let instanceId: String?     // Instance identifier
    let campaign: String?       // Campaign identifier
    let referer: String?        // Referrer information
    let adid: String?           // Advertising identifier
}
```

### Additional Parameters

| Parameter | Type | Description | Use Case |
|-----------|------|-------------|----------|
| `thirdId` | String | Third-party service ID | Analytics integration |
| `instanceId` | String | Instance identifier | Multi-instance apps |
| `campaign` | String | Campaign tracking | Marketing attribution |
| `referer` | String | Referrer information | Traffic source tracking |
| `adid` | String | Advertising ID | Ad network integration |

## 🎯 Best Practices

### 1. Security Configuration

```swift
// ✅ Good: Use environment-specific keys
#if DEBUG
let serviceKey = "debug_service_key"
let serviceIv = "debug_service_iv"
#else
let serviceKey = "production_service_key"
let serviceIv = "production_service_iv"
#endif

// ❌ Bad: Hardcoded production keys in debug builds
let serviceKey = "production_key"
```

### 2. Configuration Validation

```swift
struct NetworkConfigValidator {
    static func validate(_ config: NetworkConfig) -> Bool {
        guard !config.serviceId.isEmpty,
              !config.serviceUrl.isEmpty,
              !config.serviceKey.isEmpty,
              !config.serviceIv.isEmpty,
              !config.publicKey.isEmpty else {
            return false
        }
        
        // Validate URL format
        guard URL(string: config.serviceUrl) != nil else {
            return false
        }
        
        return true
    }
}
```

### 3. Environment-Specific Configuration

```swift
enum Environment {
    case development
    case staging
    case production
    
    var serviceUrl: String {
        switch self {
        case .development:
            return "https://dev-api.example.com"
        case .staging:
            return "https://staging-api.example.com"
        case .production:
            return "https://api.example.com"
        }
    }
    
    var configKeys: [ConfigKeyItem] {
        switch self {
        case .development:
            return [ConfigKeyItem(configKey: "dev_config")]
        case .staging:
            return [ConfigKeyItem(configKey: "staging_config")]
        case .production:
            return [ConfigKeyItem(configKey: "prod_config")]
        }
    }
}
```

## 📝 Configuration Examples

### Basic Configuration

```swift
let basicConfig = NetworkConfig(
    serviceId: "my_game_app",
    bundleName: Bundle.main.bundleIdentifier ?? "",
    serviceUrl: "https://api.mygame.com",
    serviceKey: "your_service_key",
    serviceIv: "your_service_iv",
    publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----",
    configKeyItems: nil,
    other: nil
)
```

### Advanced Configuration

```swift
let advancedConfig = NetworkConfig(
    serviceId: "premium_game_app",
    bundleName: Bundle.main.bundleIdentifier ?? "",
    serviceUrl: "https://api.premiumgame.com",
    serviceKey: "premium_service_key",
    serviceIv: "premium_service_iv",
    publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----",
    configKeyItems: [
        ConfigKeyItem(configKey: "premium_config"),
        ConfigKeyItem(adjustKey: "premium_analytics"),
        ConfigKeyItem(adUnitKey: "premium_ads")
    ],
    other: OtherConfig(
        thirdId: "premium_partner",
        instanceId: "main_instance",
        campaign: "launch_2024",
        referer: "app_store",
        adid: "premium_ad_network"
    )
)
```

### Objective-C Configuration

```objective-c
NSArray<ConfigKeyItem *> *configKeys = @[
    [[ConfigKeyItem alloc] initWithConfigKey:@"objc_config"],
    [[ConfigKeyItem alloc] initWithAdjustKey:@"objc_analytics"],
    [[ConfigKeyItem alloc] initWithAdUnitKey:@"objc_ads"]
];

OtherConfig *otherConfig = [[OtherConfig alloc] initWithThirdId:@"objc_partner"
                                                     instanceId:@"objc_instance"
                                                        campaign:@"objc_campaign"
                                                          referer:@"objc_referer"
                                                             adid:@"objc_adid"];

NetworkConfig *config = [[NetworkConfig alloc] initWithServiceId:@"objc_app"
                                                      bundleName:@"com.example.objcapp"
                                                      serviceUrl:@"https://api.objcapp.com"
                                                      serviceKey:@"objc_service_key"
                                                       serviceIv:@"objc_service_iv"
                                                       publicKey:@"-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
                                                  configKeyItems:configKeys
                                                           other:otherConfig];
```

## 🔒 Security Considerations

### Key Management

1. **Never commit keys to version control**
2. **Use environment variables or secure key storage**
3. **Rotate keys regularly**
4. **Use different keys for different environments**

### Encryption

1. **Always use HTTPS for service URLs**
2. **Validate public key format**
3. **Ensure proper key lengths**
4. **Use secure random generation for IVs**

## 📱 Platform-Specific Configuration

### iOS Configuration

```swift
// iOS-specific settings
let iosConfig = NetworkConfig(
    serviceId: "ios_game_app",
    bundleName: Bundle.main.bundleIdentifier ?? "",
    serviceUrl: "https://ios-api.example.com",
    serviceKey: "ios_service_key",
    serviceIv: "ios_service_iv",
    publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----",
    configKeyItems: [
        ConfigKeyItem(configKey: "ios_config"),
        ConfigKeyItem(adjustKey: "ios_analytics")
    ],
    other: OtherConfig(
        thirdId: "ios_platform",
        instanceId: "ios_main"
    )
)
```

### Unity Integration

```swift
// Unity-specific configuration
let unityConfig = NetworkConfig(
    serviceId: "unity_game_app",
    bundleName: Bundle.main.bundleIdentifier ?? "",
    serviceUrl: "https://unity-api.example.com",
    serviceKey: "unity_service_key",
    serviceIv: "unity_service_iv",
    publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----",
    configKeyItems: [
        ConfigKeyItem(configKey: "unity_config"),
        ConfigKeyItem(adUnitKey: "unity_ads")
    ],
    other: OtherConfig(
        thirdId: "unity_platform",
        instanceId: "unity_main"
    )
)
```

## 🔍 Configuration Validation

### Runtime Validation

```swift
extension NetworkConfig {
    var isValid: Bool {
        // Check required fields
        guard !serviceId.isEmpty,
              !bundleName.isEmpty,
              !serviceUrl.isEmpty,
              !serviceKey.isEmpty,
              !serviceIv.isEmpty,
              !publicKey.isEmpty else {
            return false
        }
        
        // Validate URL
        guard URL(string: serviceUrl) != nil else {
            return false
        }
        
        // Validate public key format
        guard publicKey.contains("-----BEGIN PUBLIC KEY-----") &&
              publicKey.contains("-----END PUBLIC KEY-----") else {
            return false
        }
        
        return true
    }
}
```

### Configuration Testing

```swift
class ConfigurationTester {
    static func testConfiguration(_ config: NetworkConfig) {
        guard config.isValid else {
            print("❌ Configuration validation failed")
            return
        }
        
        print("✅ Configuration validation passed")
        print("Service ID: \(config.serviceId)")
        print("Service URL: \(config.serviceUrl)")
        print("Bundle Name: \(config.bundleName)")
        
        if let configKeys = config.configKeyItems {
            print("Configuration Keys: \(configKeys.count)")
        }
        
        if let other = config.other {
            print("Additional Config: \(other)")
        }
    }
}
```

## 📞 Support

For configuration-related questions:

- Check the [Integration Guide](INTEGRATION_GUIDE.md)
- Review [API Reference](API_REFERENCE.md)
- Contact support: [support@shuge.com](mailto:support@shuge.com)

---

**Need help with configuration?** Check our [FAQ](FAQ.md) or [contact support](mailto:support@shuge.com).
