# GrowthSDK FAQ & Troubleshooting

Common issues, solutions, and troubleshooting guide for GrowthSDK.

## 📋 Table of Contents

1. [General Questions](#general-questions)
2. [Installation Issues](#installation-issues)
3. [Initialization Problems](#initialization-problems)
4. [Advertising Issues](#advertising-issues)
5. [Unity Integration Issues](#unity-integration-issues)
6. [Performance Problems](#performance-problems)
7. [Build & Runtime Errors](#build--runtime-errors)
8. [Network & Configuration Issues](#network--configuration-issues)

## ❓ General Questions

### Q: What is GrowthSDK?

**A:** GrowthSDK is a comprehensive iOS SDK framework designed for game growth and monetization. It provides:

- **Unified Advertising Solution** - Multiple ad formats and networks
- **Game Growth Tools** - User engagement and retention features
- **Analytics & Insights** - Performance monitoring and optimization
- **Unity Integration** - Seamless cross-platform development
- **Security & Privacy** - Enterprise-grade protection and compliance

### Q: What iOS versions are supported?

**A:** GrowthSDK supports iOS 14.0 and above. This ensures compatibility with modern iOS features while maintaining broad device support.

### Q: Is GrowthSDK free to use?

**A:** GrowthSDK is a commercial SDK. Please contact our business team at [business@shuge.com](mailto:business@shuge.com) for pricing and licensing information.

### Q: Can I use GrowthSDK in production apps?

**A:** Yes, GrowthSDK is designed for production use and includes enterprise-grade features like:

- Production-ready ad networks
- Comprehensive error handling
- Performance optimization
- Security features
- Analytics and monitoring

## 📦 Installation Issues

### Q: CocoaPods installation fails with "Unable to find a specification"

**A:** This usually indicates a CocoaPods repository issue. Try these solutions:

```bash
# Update CocoaPods repository
pod repo update

# Clean CocoaPods cache
pod cache clean --all

# Reinstall
pod install
```

**Alternative solution:**
```bash
# Remove Podfile.lock and Pods directory
rm Podfile.lock
rm -rf Pods

# Reinstall
pod install
```

### Q: Build fails with "Framework not found GrowthSDK"

**A:** This indicates the framework isn't properly linked. Check:

1. **Framework linking:**
   - Target → General → Frameworks, Libraries, and Embedded Content
   - Ensure GrowthSDK.framework is listed
   - Set to "Embed & Sign"

2. **Search paths:**
   - Build Settings → Framework Search Paths
   - Add path to GrowthSDK.framework location

3. **CocoaPods integration:**
   - Use `.xcworkspace` file, not `.xcodeproj`
   - Ensure `use_frameworks!` is in Podfile

### Q: "Always Embed Swift Standard Libraries" error

**A:** This is required for mixed Swift/Objective-C projects. Fix:

1. **Target → Build Settings**
2. **Search for "Always Embed Swift Standard Libraries"**
3. **Set to "Yes"**

**Note:** This setting is automatically configured when using CocoaPods.

### Q: Missing required frameworks

**A:** Ensure all required dependencies are included:

```ruby
# Required dependencies
pod 'AppLovinSDK', '13.3.1'
pod 'KwaiAdsSDK', '1.2.0'

# Optional ad mediation adapters
pod 'AppLovinMediationGoogleAdapter', '12.9.0.0'
pod 'AppLovinMediationFacebookAdapter', '6.20.1.0'
# ... other adapters as needed
```

## 🚀 Initialization Problems

### Q: SDK initialization fails with "serviceInitFailed"

**A:** This indicates a configuration or network issue. Check:

1. **Configuration parameters:**
   ```swift
   // Verify all required fields
   let config = NetworkConfig(
       serviceId: "your_service_id",        // ✅ Required
       bundleName: Bundle.main.bundleIdentifier ?? "",  // ✅ Required
       serviceUrl: "https://api.example.com",  // ✅ Required
       serviceKey: "your_service_key",      // ✅ Required
       serviceIv: "your_service_iv",        // ✅ Required
       publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"  // ✅ Required
   )
   ```

2. **Network connectivity:**
   - Check internet connection
   - Verify service URL is accessible
   - Test with different networks

3. **Service credentials:**
   - Verify service ID is correct
   - Check service key and IV
   - Ensure public key format is correct

### Q: "alreadyInitialized" error

**A:** This occurs when trying to initialize an already initialized SDK. Solutions:

1. **Check initialization status:**
   ```swift
   if !GrowthKit.shared.isInitialized {
       try await GrowthKit.shared.initialize(with: config)
   }
   ```

2. **Use singleton pattern:**
   ```swift
   class SDKManager {
       static let shared = SDKManager()
       
       func initializeSDK() async throws {
           guard !GrowthKit.shared.isInitialized else { return }
           try await GrowthKit.shared.initialize(with: config)
       }
   }
   ```

### Q: Initialization hangs indefinitely

**A:** This usually indicates a network timeout or deadlock. Solutions:

1. **Add timeout handling:**
   ```swift
   Task {
       do {
           try await withTimeout(seconds: 30) {
               try await GrowthKit.shared.initialize(with: config)
           }
       } catch {
           print("Initialization timeout: \(error)")
       }
   }
   ```

2. **Check network configuration:**
   - Verify service URL is correct
   - Check firewall/proxy settings
   - Test with different networks

3. **Enable detailed logging:**
   ```swift
   GrowthKit.isLoggingEnabled = true
   ```

## 📱 Advertising Issues

### Q: Ads not loading

**A:** Common causes and solutions:

1. **SDK not initialized:**
   ```swift
   guard GrowthKit.shared.isInitialized else {
       print("SDK not initialized")
       return
   }
   ```

2. **Network issues:**
   - Check internet connectivity
   - Verify ad network configuration
   - Check ad network health

3. **Configuration problems:**
   - Verify AdMob App ID in Info.plist
   - Check SKAdNetwork configuration
   - Ensure proper permissions

### Q: Ads load but don't display

**A:** This indicates a view hierarchy issue. Check:

1. **View controller presentation:**
   ```swift
   // Ensure proper presentation
   if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
       rootVC.present(adViewController, animated: true)
   }
   ```

2. **Window setup (for ad mediation):**
   ```swift
   // AppDelegate must expose window property
   var window: UIWindow?
   ```

3. **View hierarchy:**
   - Check for overlapping views
   - Verify view controller lifecycle
   - Ensure proper window management

### Q: Low ad fill rate

**A:** Improve fill rate with these strategies:

1. **Add more ad networks:**
   ```ruby
   pod 'AppLovinMediationGoogleAdapter', '12.9.0.0'
   pod 'AppLovinMediationFacebookAdapter', '6.20.1.0'
   pod 'AppLovinMediationBigoAdsAdapter', '4.9.3.0'
   # ... add more networks
   ```

2. **Optimize ad placement:**
   - Show ads at natural break points
   - Avoid excessive ad frequency
   - Implement proper user experience

3. **Geographic targeting:**
   - Check ad network coverage in your region
   - Consider local ad networks
   - Test with different user locations

### Q: Ad callbacks not working

**A:** Ensure proper callback implementation:

1. **Implement AdCallbacks protocol:**
   ```swift
   class AdManager: NSObject, AdCallbacks {
       func onStartLoading(_ style: ADStyle) {
           print("Ad loading started")
       }
       
       func onLoadSuccess(_ style: ADStyle) {
           print("Ad loaded successfully")
       }
       
       // ... implement other callbacks
   }
   ```

2. **Pass callbacks to showAd:**
   ```swift
   GrowthKit.showAd(with: .rewarded, callbacks: adManager)
   ```

3. **Check callback registration:**
   - Ensure callback object is retained
   - Verify protocol conformance
   - Check for memory issues

## 🎮 Unity Integration Issues

### Q: Unity methods not calling native code

**A:** Check Unity-iOS bridge setup:

1. **Method signatures:**
   ```csharp
   [DllImport("__Internal")]
   private static extern void OnAdShow(string adType);
   ```

2. **Unity build settings:**
   - Platform: iOS
   - Scripting Backend: IL2CPP
   - Target minimum iOS Version: 14.0

3. **Xcode project setup:**
   - Ensure UnityFramework.framework is linked
   - Set "Embed & Sign" for UnityFramework
   - Check UnityCallProvider implementation

### Q: Native callbacks not reaching Unity

**A:** Verify Unity message sending:

1. **UnitySendMessage usage:**
   ```objc
   UnitySendMessage("GameObjectName", "MethodName", "Message");
   ```

2. **GameObject names:**
   - Ensure GameObject name matches exactly
   - Check for typos and case sensitivity
   - Verify GameObject exists in scene

3. **Method names:**
   - Ensure method name matches exactly
   - Check for typos and case sensitivity
   - Verify method is public

### Q: Unity crashes when showing ads

**A:** Common causes and solutions:

1. **View controller hierarchy:**
   ```objc
   // Ensure proper view controller setup
   UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
   [rootVC presentViewController:adVC animated:YES completion:nil];
   ```

2. **Memory management:**
   - Check for retain cycles
   - Ensure proper object lifecycle
   - Monitor memory usage

3. **Thread safety:**
   ```objc
   dispatch_async(dispatch_get_main_queue(), ^{
       // UI operations must be on main thread
       [self showAd];
   });
   ```

## ⚡ Performance Problems

### Q: Slow ad loading

**A:** Optimize ad loading performance:

1. **Implement ad preloading:**
   ```swift
   // Preload ads in background
   GrowthKit.shared.reloadAppOpenAd()
   GrowthKit.shared.reloadBiddingAd()
   ```

2. **Optimize ad frequency:**
   ```swift
   class AdFrequencyManager {
       private let minimumInterval: TimeInterval = 30
       
       func canShowAd() -> Bool {
           // Implement frequency capping
           return true
       }
   }
   ```

3. **Background loading:**
   ```swift
   Task { @MainActor in
       // Load ads in background
       await loadAdsInBackground()
   }
   ```

### Q: High memory usage

**A:** Reduce memory footprint:

1. **Proper cleanup:**
   ```swift
   deinit {
       // Clean up resources
       removeObservers()
       cancelTasks()
   }
   ```

2. **Image optimization:**
   - Use appropriate image formats
   - Implement image caching
   - Monitor image memory usage

3. **View management:**
   - Remove unused views
   - Implement proper view lifecycle
   - Monitor view hierarchy

### Q: Battery drain

**A:** Optimize battery usage:

1. **Background processing:**
   ```swift
   // Minimize background operations
   // Use efficient data structures
   // Implement proper caching
   ```

2. **Network optimization:**
   - Batch network requests
   - Use efficient protocols
   - Implement proper retry logic

3. **UI optimization:**
   - Minimize UI updates
   - Use efficient animations
   - Implement proper view recycling

## 🔨 Build & Runtime Errors

### Q: Build fails with "Undefined symbols"

**A:** This indicates missing framework linking. Fix:

1. **Check framework linking:**
   - Target → General → Frameworks, Libraries, and Embedded Content
   - Ensure all required frameworks are listed
   - Set to "Embed & Sign"

2. **Search paths:**
   - Build Settings → Framework Search Paths
   - Add paths to framework locations

3. **CocoaPods integration:**
   - Use `.xcworkspace` file
   - Ensure `pod install` completed successfully

### Q: Runtime crash with "EXC_BAD_ACCESS"

**A:** This usually indicates memory management issues. Debug:

1. **Enable Zombie Objects:**
   - Edit Scheme → Run → Diagnostics
   - Enable "Zombie Objects"

2. **Check retain cycles:**
   ```swift
   // Use weak references where appropriate
   weak var delegate: AdCallbacks?
   ```

3. **Verify object lifecycle:**
   - Ensure objects are properly retained
   - Check for premature deallocation
   - Monitor memory usage

### Q: "Thread 1: signal SIGABRT" crash

**A:** This indicates an assertion failure. Common causes:

1. **SDK not initialized:**
   ```swift
   guard GrowthKit.shared.isInitialized else {
       fatalError("SDK not initialized")
   }
   ```

2. **Invalid configuration:**
   - Check configuration parameters
   - Verify required fields
   - Test with minimal configuration

3. **Permission issues:**
   - Check Info.plist configuration
   - Verify required permissions
   - Test on different devices

## 🌐 Network & Configuration Issues

### Q: Network requests fail

**A:** Check network configuration:

1. **HTTP vs HTTPS:**
   ```xml
   <!-- Allow HTTP requests if needed -->
   <key>NSAppTransportSecurity</key>
   <dict>
     <key>NSAllowsArbitraryLoads</key>
     <true/>
   </dict>
   ```

2. **Network permissions:**
   - Check firewall settings
   - Verify proxy configuration
   - Test with different networks

3. **Service configuration:**
   - Verify service URL
   - Check service credentials
   - Test service endpoints

### Q: Configuration validation fails

**A:** Implement proper validation:

1. **Parameter validation:**
   ```swift
   extension NetworkConfig {
       var isValid: Bool {
           guard !serviceId.isEmpty,
                 !serviceUrl.isEmpty,
                 !serviceKey.isEmpty,
                 !serviceIv.isEmpty,
                 !publicKey.isEmpty else {
               return false
           }
           
           guard URL(string: serviceUrl) != nil else {
               return false
           }
           
           return true
       }
   }
   ```

2. **Environment-specific config:**
   ```swift
   #if DEBUG
   let serviceUrl = "https://dev-api.example.com"
   #else
   let serviceUrl = "https://api.example.com"
   #endif
   ```

3. **Configuration testing:**
   ```swift
   class ConfigurationTester {
       static func testConfiguration(_ config: NetworkConfig) {
           guard config.isValid else {
               print("Configuration validation failed")
               return
           }
           print("Configuration validation passed")
       }
   }
   ```

### Q: SKAdNetwork configuration issues

**A:** Ensure proper SKAdNetwork setup:

1. **Complete SKAdNetworkItems array:**
   - Include all required network identifiers
   - Verify identifier format
   - Check for typos

2. **Network compatibility:**
   - Ensure ad networks support SKAdNetwork
   - Check network-specific requirements
   - Test with different networks

3. **Testing:**
   - Test on iOS 14+ devices
   - Verify network attribution
   - Check conversion tracking

## 🔍 Debugging Tips

### Enable Debug Mode

```swift
// Enable SDK logging
GrowthKit.isLoggingEnabled = true

// Show debug panel
GrowthKit.shared.showAdDebugger()
```

### Check SDK Status

```swift
// Check initialization status
let isReady = GrowthKit.shared.isInitialized
let state = GrowthKit.shared.state

print("SDK ready: \(isReady)")
print("SDK state: \(state)")
```

### Monitor Ad Events

```swift
class DebugAdCallbacks: NSObject, AdCallbacks {
    func onStartLoading(_ style: ADStyle) {
        print("🔄 Ad loading started: \(style.name)")
    }
    
    func onLoadSuccess(_ style: ADStyle) {
        print("✅ Ad loaded: \(style.name)")
    }
    
    func onLoadFailed(_ style: ADStyle, error: Error?) {
        print("❌ Ad load failed: \(style.name) - \(error?.localizedDescription ?? "Unknown")")
    }
    
    // ... implement other callbacks
}
```

## 📞 Getting Help

### Before Contacting Support

1. **Check this FAQ** for common solutions
2. **Review documentation** for your specific use case
3. **Enable debug logging** and check console output
4. **Test with minimal configuration** to isolate issues
5. **Check system requirements** and compatibility

### Contact Information

- **Technical Support:** [support@shuge.com](mailto:support@shuge.com)
- **Business Inquiries:** [business@shuge.com](mailto:business@shuge.com)
- **GitHub Issues:** [Report Issues](https://github.com/shuge-developer/GrowthSDK/issues)
- **Documentation:** [Complete Documentation](INTEGRATION_GUIDE.md)

### When Contacting Support

Please include:

1. **SDK version:** `GrowthKit.sdkVersion`
2. **iOS version:** Device iOS version
3. **Xcode version:** Development environment
4. **Error details:** Full error messages and stack traces
5. **Configuration:** Relevant configuration details
6. **Steps to reproduce:** Detailed reproduction steps
7. **Console logs:** Relevant log output

---

**Still need help?** Contact our support team at [support@shuge.com](mailto:support@shuge.com).
