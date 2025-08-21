# GrowthSDK Requirements & Permissions

System requirements, permissions, and configuration details for GrowthSDK integration.

## 📋 Table of Contents

1. [System Requirements](#system-requirements)
2. [Required Permissions](#required-permissions)
3. [Info.plist Configuration](#infoplist-configuration)
4. [SKAdNetwork Configuration](#skadnetwork-configuration)
5. [Dependencies](#dependencies)
6. [Build Settings](#build-settings)
7. [Privacy & Compliance](#privacy--compliance)

## 💻 System Requirements

### Development Environment

- **Xcode:** 14.0+
- **iOS Deployment Target:** 14.0+
- **Swift:** 5.0+
- **CocoaPods:** 1.10.0+
- **macOS:** 12.0+ (for development)

### Runtime Requirements

- **iOS:** 14.0+
- **Architecture:** ARM64 (iPhone), x86_64 (Simulator)
- **Memory:** 512MB+ available RAM
- **Storage:** 50MB+ available storage
- **Network:** Internet connection required

### Device Support

- **iPhone:** iPhone 6s and newer
- **iPad:** iPad Air 2 and newer
- **iPod touch:** 7th generation and newer
- **Simulator:** iOS 14.0+ simulator

## 🔐 Required Permissions

### 1. Network Access

**Purpose:** SDK requires internet access for ad loading, analytics, and configuration.

**Configuration:**
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

**Note:** While this allows HTTP requests, HTTPS is strongly recommended for production.

### 2. App Tracking Transparency (ATT)

**Purpose:** Required for iOS 14.5+ to access IDFA for advertising and analytics.

**Configuration:**
```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use your device identifier for advertising optimization and attribution analysis.</string>
```

**Implementation:**
```swift
import AppTrackingTransparency

func requestTrackingPermission() {
    if #available(iOS 14.5, *) {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                print("Tracking authorized")
            case .denied:
                print("Tracking denied")
            case .restricted:
                print("Tracking restricted")
            case .notDetermined:
                print("Tracking not determined")
            @unknown default:
                print("Unknown tracking status")
            }
        }
    }
}
```

**Best Practices:**
- Request permission at appropriate time (not immediately on app launch)
- Explain the value to users before requesting
- Handle all permission states gracefully
- Provide alternative experiences for denied users

### 3. AdMob App ID

**Purpose:** Required for Google AdMob integration and compliance.

**Configuration:**
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

**Note:** Replace with your actual AdMob App ID. Without this, the app will crash.

### 4. Background App Refresh (Optional)

**Purpose:** Enables background ad preloading for better user experience.

**Configuration:**
```xml
<key>UIBackgroundModes</key>
<array>
  <string>background-processing</string>
</array>
```

**Note:** This is optional but recommended for optimal ad performance.

## 📱 Info.plist Configuration

### Complete Info.plist Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- Basic App Information -->
  <key>CFBundleIdentifier</key>
  <string>com.yourcompany.yourapp</string>
  
  <key>CFBundleVersion</key>
  <string>1.0</string>
  
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  
  <key>CFBundleExecutable</key>
  <string>YourApp</string>
  
  <key>CFBundleDisplayName</key>
  <string>Your App Name</string>
  
  <!-- Required Permissions -->
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
  </dict>
  
  <key>NSUserTrackingUsageDescription</key>
  <string>We use your device identifier for advertising optimization and attribution analysis.</string>
  
  <key>GADApplicationIdentifier</key>
  <string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
  
  <!-- Optional Background Modes -->
  <key>UIBackgroundModes</key>
  <array>
    <string>background-processing</string>
  </array>
  
  <!-- Launch Screen -->
  <key>UILaunchStoryboardName</key>
  <string>LaunchScreen</string>
  
  <!-- Device Orientation -->
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
  
  <!-- iPad Support -->
  <key>UISupportedInterfaceOrientations~ipad</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
</dict>
</plist>
```

### Required Keys Summary

| Key | Required | Description |
|-----|----------|-------------|
| `CFBundleIdentifier` | ✅ | App bundle identifier |
| `CFBundleVersion` | ✅ | Build version |
| `CFBundleShortVersionString` | ✅ | App version |
| `CFBundleExecutable` | ✅ | Executable name |
| `CFBundleDisplayName` | ✅ | App display name |
| `NSAppTransportSecurity` | ✅ | Network security settings |
| `NSUserTrackingUsageDescription` | ✅ | ATT permission description |
| `GADApplicationIdentifier` | ✅ | AdMob App ID |

## 🌐 SKAdNetwork Configuration

### Complete SKAdNetworkItems Array

```xml
<key>SKAdNetworkItems</key>
<array>
    <!-- AppLovin -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>22mmun2rn5.skadnetwork</string>
    </dict>
    
    <!-- Google AdMob -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    
    <!-- Facebook -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v79kvwwj4g.skadnetwork</string>
    </dict>
    
    <!-- Unity -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4dzt52r2t5.skadnetwork</string>
    </dict>
    
    <!-- Chartboost -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>f38h382jlk.skadnetwork</string>
    </dict>
    
    <!-- Fyber -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hs6bdukanm.skadnetwork</string>
    </dict>
    
    <!-- InMobi -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>su67r6k2v3.skadnetwork</string>
    </dict>
    
    <!-- Vungle -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>gta8lk7p23.skadnetwork</string>
    </dict>
    
    <!-- Mintegral -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>k6y4y55b64.skadnetwork</string>
    </dict>
    
    <!-- Moloco -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7ug5zh24hu.skadnetwork</string>
    </dict>
    
    <!-- ByteDance -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>238da6jt44.skadnetwork</string>
    </dict>
    
    <!-- BigoAds -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>24t9a8vw3c.skadnetwork</string>
    </dict>
    
    <!-- Additional networks... -->
    <!-- Include all networks you plan to use -->
</array>
```

### SKAdNetwork Best Practices

1. **Include All Networks:**
   - Add SKAdNetwork identifiers for all ad networks you use
   - Keep the list updated as you add/remove networks

2. **Testing:**
   - Test SKAdNetwork integration on iOS 14+ devices
   - Verify attribution tracking works correctly
   - Test with different ad networks

3. **Compliance:**
   - Ensure all networks support SKAdNetwork
   - Follow Apple's SKAdNetwork guidelines
   - Monitor for network-specific requirements

## 📦 Dependencies

### Required Dependencies

```ruby
target 'YourAppTarget' do
  # Core SDK
  pod 'GrowthSDK', '~> 1.0.0'
  
  # Required ad networks
  pod 'AppLovinSDK', '13.3.1'
  pod 'KwaiAdsSDK', '1.2.0'
end
```

### Optional Ad Mediation Adapters

```ruby
target 'YourAppTarget' do
  # Major networks
  pod 'AppLovinMediationGoogleAdapter', '12.9.0.0'
  pod 'AppLovinMediationFacebookAdapter', '6.20.1.0'
  
  # Gaming networks
  pod 'AppLovinMediationBigoAdsAdapter', '4.9.3.0'
  pod 'AppLovinMediationByteDanceAdapter', '7.5.0.5.0'
  
  # Performance networks
  pod 'AppLovinMediationChartboostAdapter', '9.9.2.1'
  pod 'AppLovinMediationFyberAdapter', '8.3.8.0'
  pod 'AppLovinMediationInMobiAdapter', '10.8.6.0'
  pod 'AppLovinMediationVungleAdapter', '7.5.3.0'
  
  # Emerging networks
  pod 'AppLovinMediationMintegralAdapter', '7.7.9.0.0'
  pod 'AppLovinMediationMolocoAdapter', '3.12.1.0'
end
```

### Manual Integration Dependencies

If not using CocoaPods, ensure these frameworks are manually linked:

- **GrowthSDK.xcframework**
- **AppLovinSDK.framework**
- **KwaiAdsSDK.framework**
- **UnityFramework.framework** (for Unity integration)

## ⚙️ Build Settings

### Required Build Settings

1. **iOS Deployment Target:**
   - Set to iOS 14.0 or higher

2. **Always Embed Swift Standard Libraries:**
   - Set to "Yes" for mixed Swift/Objective-C projects

3. **Framework Search Paths:**
   - Include paths to all required frameworks

4. **Other Linker Flags:**
   - Ensure proper linking for all dependencies

### Build Settings Configuration

```bash
# In Xcode Build Settings:

# iOS Deployment Target
IPHONEOS_DEPLOYMENT_TARGET = 14.0

# Always Embed Swift Standard Libraries
ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES

# Framework Search Paths
FRAMEWORK_SEARCH_PATHS = $(inherited) $(SRCROOT)/Frameworks

# Other Linker Flags
OTHER_LDFLAGS = $(inherited) -ObjC
```

### Unity-Specific Build Settings

For Unity integration projects:

1. **Scripting Backend:** IL2CPP
2. **Target Architectures:** ARM64
3. **Minimum iOS Version:** 14.0
4. **Framework Linking:** UnityFramework.framework

## 🔒 Privacy & Compliance

### GDPR Compliance

**Data Collection:**
- Device identifiers (IDFA, IDFV)
- App usage analytics
- Ad interaction data
- Performance metrics

**User Rights:**
- Right to access personal data
- Right to delete personal data
- Right to data portability
- Right to object to processing

**Implementation:**
```swift
class PrivacyManager {
    func requestDataAccess() {
        // Implement data access request
    }
    
    func deleteUserData() {
        // Implement data deletion
    }
    
    func exportUserData() {
        // Implement data export
    }
}
```

### CCPA Compliance

**California Consumer Privacy Act:**
- Right to know what data is collected
- Right to delete personal data
- Right to opt-out of data sale
- Right to non-discrimination

### COPPA Compliance

**Children's Online Privacy Protection Act:**
- Special handling for users under 13
- Parental consent requirements
- Limited data collection
- Age verification mechanisms

### Privacy Policy Requirements

Your app's privacy policy must include:

1. **Data Collection:**
   - What data is collected
   - How data is used
   - Data retention policies

2. **Third-Party Services:**
   - Ad network data usage
   - Analytics service policies
   - Data sharing practices

3. **User Rights:**
   - How to exercise privacy rights
   - Contact information for privacy requests
   - Appeal processes

4. **Updates:**
   - How policy changes are communicated
   - Effective dates
   - Version history

## 🧪 Testing Requirements

### Device Testing

**Required Devices:**
- iPhone 6s or newer (iOS 14.0+)
- iPad Air 2 or newer (iOS 14.0+)
- Simulator (iOS 14.0+)

**Test Scenarios:**
- Fresh app installation
- App updates
- Background/foreground transitions
- Network connectivity changes
- Permission state changes

### Network Testing

**Network Conditions:**
- WiFi (various speeds)
- Cellular (various carriers)
- Network switching
- Poor connectivity
- No connectivity

**Ad Network Testing:**
- Test with all integrated networks
- Verify fill rates
- Check error handling
- Monitor performance metrics

### Permission Testing

**Permission States:**
- Not determined
- Authorized
- Denied
- Restricted

**Permission Flows:**
- First-time permission request
- Permission change handling
- Graceful degradation
- Alternative experiences

## 📊 Performance Requirements

### Memory Usage

**Target Memory:**
- Peak memory: < 100MB
- Background memory: < 50MB
- Memory leaks: None

**Monitoring:**
```swift
class MemoryMonitor {
    func checkMemoryUsage() {
        let memoryUsage = ProcessInfo.processInfo.physicalMemory
        print("Memory usage: \(memoryUsage / 1024 / 1024) MB")
    }
}
```

### Battery Impact

**Target Battery:**
- Background processing: < 5% per hour
- Ad loading: < 2% per ad
- Overall impact: < 10% per day

**Optimization:**
```swift
class BatteryOptimizer {
    func optimizeBackgroundTasks() {
        // Minimize background processing
        // Use efficient algorithms
        // Implement proper caching
    }
}
```

### Network Efficiency

**Target Metrics:**
- Ad load time: < 3 seconds
- Configuration fetch: < 1 second
- Analytics upload: < 500ms

**Optimization:**
```swift
class NetworkOptimizer {
    func optimizeRequests() {
        // Batch network requests
        // Use efficient protocols
        // Implement proper retry logic
    }
}
```

## 📱 Platform-Specific Requirements

### iOS Requirements

**iOS 14.0+:**
- Full feature support
- Modern privacy features
- Latest ad network capabilities

**iOS 14.5+:**
- App Tracking Transparency
- Enhanced privacy controls
- SKAdNetwork attribution

**iOS 15.0+:**
- Enhanced performance
- Better background processing
- Improved security features

### Unity Integration Requirements

**Unity Version:**
- Unity 2020.3 LTS or newer
- iOS Build Support module
- IL2CPP scripting backend

**Build Settings:**
- Target Platform: iOS
- Architecture: ARM64
- Minimum iOS Version: 14.0

**Framework Integration:**
- UnityFramework.framework linking
- Proper view controller setup
- Native bridge implementation

## 🔍 Validation Checklist

### Pre-Integration Checklist

- [ ] iOS 14.0+ deployment target set
- [ ] Required frameworks available
- [ ] Info.plist configured
- [ ] SKAdNetwork items added
- [ ] Permissions configured
- [ ] Build settings verified

### Integration Checklist

- [ ] SDK properly initialized
- [ ] Ad networks configured
- [ ] Callbacks implemented
- [ ] Error handling in place
- [ ] Privacy compliance verified
- [ ] Performance optimized

### Testing Checklist

- [ ] All devices tested
- [ ] Network conditions verified
- [ ] Permission states tested
- [ ] Ad networks working
- [ ] Performance metrics met
- [ ] Privacy features verified

## 📞 Support

For requirements-related questions:

- Check the [Integration Guide](INTEGRATION_GUIDE.md)
- Review [Configuration Guide](CONFIGURATION_GUIDE.md)
- Contact support: [support@shuge.com](mailto:support@shuge.com)

---

**Need help with requirements?** Check our [FAQ](FAQ.md) or [contact support](mailto:support@shuge.com).
