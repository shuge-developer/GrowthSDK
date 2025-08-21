# GrowthSDK Advertising Integration Guide

Comprehensive guide for integrating various ad formats and networks with GrowthSDK.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Supported Ad Formats](#supported-ad-formats)
3. [Ad Networks](#ad-networks)
4. [Basic Ad Integration](#basic-ad-integration)
5. [Advanced Ad Features](#advanced-ad-features)
6. [Ad Callbacks](#ad-callbacks)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

## 🎯 Overview

GrowthSDK provides a unified advertising solution that supports multiple ad formats and networks:

- **Rewarded Video Ads** - User engagement with rewards
- **Interstitial Ads** - Full-screen ad experiences  
- **App Open Ads** - Launch screen monetization
- **Bidding Ads** - Real-time auction optimization

## 📱 Supported Ad Formats

### ADStyle Enum

```swift
@objc public enum ADStyle: Int {
    case rewarded = 0   // Rewarded video ads
    case inserted = 1   // Interstitial ads
    case appOpen = 2    // App open ads
}
```

### Ad Format Characteristics

| Format | Type | User Experience | Monetization |
|--------|------|-----------------|--------------|
| **Rewarded** | Video | Interactive, user-initiated | High CPM, user engagement |
| **Interstitial** | Full-screen | Non-intrusive, timed | Medium CPM, good fill rate |
| **App Open** | Launch screen | Seamless integration | High fill rate, consistent revenue |

## 🌐 Ad Networks

### Primary Networks

- **AdMob** - Google's mobile advertising platform
- **AppLovin** - Performance-based advertising
- **KwaiAds** - ByteDance advertising network

### Mediation Adapters

Optional ad mediation adapters for expanded reach:

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

## 🚀 Basic Ad Integration

### 1. Simple Ad Display

```swift
// Show rewarded ad without callbacks
GrowthKit.showAd(with: .rewarded)

// Show interstitial ad
GrowthKit.showAd(with: .inserted)

// Show app open ad
GrowthKit.showAd(with: .appOpen)
```

### 2. Ad Display with Callbacks

```swift
class AdManager: NSObject, AdCallbacks {
    
    func showRewardedAd() {
        GrowthKit.showAd(with: .rewarded, callbacks: self)
    }
    
    func showInterstitialAd() {
        GrowthKit.showAd(with: .inserted, callbacks: self)
    }
    
    func showAppOpenAd() {
        GrowthKit.showAd(with: .appOpen, callbacks: self)
    }
}

// MARK: - AdCallbacks
extension AdManager {
    
    func onStartLoading(_ style: ADStyle) {
        print("Ad loading started: \(style)")
        // Show loading indicator
    }
    
    func onLoadSuccess(_ style: ADStyle) {
        print("Ad loaded successfully: \(style)")
        // Hide loading indicator
    }
    
    func onLoadFailed(_ style: ADStyle, error: Error?) {
        print("Ad load failed: \(style), error: \(error?.localizedDescription ?? "Unknown")")
        // Handle load failure
    }
    
    func onShowSuccess(_ style: ADStyle) {
        print("Ad shown successfully: \(style)")
        // Track ad impression
    }
    
    func onShowFailed(_ style: ADStyle, error: Error?) {
        print("Ad show failed: \(style), error: \(error?.localizedDescription ?? "Unknown")")
        // Handle show failure
    }
    
    func onGetAdReward(_ style: ADStyle) {
        print("User earned reward from: \(style)")
        // Grant user reward
    }
    
    func onAdClick(_ style: ADStyle) {
        print("Ad clicked: \(style)")
        // Track ad click
    }
    
    func onAdClose(_ style: ADStyle) {
        print("Ad closed: \(style)")
        // Resume game/app
    }
}
```

### 3. Objective-C Implementation

```objective-c
@interface AdManager : NSObject <AdCallbacks>
- (void)showRewardedAd;
- (void)showInterstitialAd;
- (void)showAppOpenAd;
@end

@implementation AdManager

- (void)showRewardedAd {
    [GrowthKit showAdWith:ADStyleRewarded callbacks:self];
}

- (void)showInterstitialAd {
    [GrowthKit showAdWith:ADStyleInserted callbacks:self];
}

- (void)showAppOpenAd {
    [GrowthKit showAdWith:ADStyleAppOpen callbacks:self];
}

#pragma mark - AdCallbacks
- (void)onStartLoading:(ADStyle)style {
    NSLog(@"Ad loading started: %ld", (long)style);
}

- (void)onLoadSuccess:(ADStyle)style {
    NSLog(@"Ad loaded successfully: %ld", (long)style);
}

- (void)onLoadFailed:(ADStyle)style error:(NSError *)error {
    NSLog(@"Ad load failed: %ld, error: %@", (long)style, error.localizedDescription);
}

- (void)onShowSuccess:(ADStyle)style {
    NSLog(@"Ad shown successfully: %ld", (long)style);
}

- (void)onShowFailed:(ADStyle)style error:(NSError *)error {
    NSLog(@"Ad show failed: %ld, error: %@", (long)style, error.localizedDescription);
}

- (void)onGetAdReward:(ADStyle)style {
    NSLog(@"User earned reward from: %ld", (long)style);
}

- (void)onAdClick:(ADStyle)style {
    NSLog(@"Ad clicked: %ld", (long)style);
}

- (void)onAdClose:(ADStyle)style {
    NSLog(@"Ad closed: %ld", (long)style);
}

@end
```

## 🚀 Advanced Ad Features

### 1. Ad Preloading

```swift
class AdvancedAdManager {
    
    // Preload app open ads
    func preloadAppOpenAds() {
        GrowthKit.shared.reloadAppOpenAd()
    }
    
    // Preload bidding ads
    func preloadBiddingAds() {
        GrowthKit.shared.reloadBiddingAd()
    }
    
    // Check ad availability
    func isAdReady(_ style: ADStyle) -> Bool {
        // Implementation depends on SDK version
        return true
    }
}
```

### 2. Ad Debugging

```swift
class AdDebugger {
    
    // Show debug panel
    func showDebugPanel() {
        GrowthKit.shared.showAdDebugger()
    }
    
    // Enable detailed logging
    func enableDetailedLogging() {
        GrowthKit.isLoggingEnabled = true
    }
    
    // Test ad display
    func testAdDisplay(_ style: ADStyle) {
        GrowthKit.showAd(with: style)
    }
}
```

### 3. Ad Frequency Capping

```swift
class AdFrequencyManager {
    
    private var lastAdTime: [ADStyle: Date] = [:]
    private let minimumInterval: TimeInterval = 30 // 30 seconds
    
    func canShowAd(_ style: ADStyle) -> Bool {
        guard let lastTime = lastAdTime[style] else {
            return true
        }
        
        let timeSinceLastAd = Date().timeIntervalSince(lastTime)
        return timeSinceLastAd >= minimumInterval
    }
    
    func recordAdShown(_ style: ADStyle) {
        lastAdTime[style] = Date()
    }
    
    func showAdWithFrequencyCheck(_ style: ADStyle) {
        guard canShowAd(style) else {
            print("Ad frequency limit reached for: \(style)")
            return
        }
        
        GrowthKit.showAd(with: style)
        recordAdShown(style)
    }
}
```

## 📊 Ad Callbacks

### Callback Protocol

```swift
@objc protocol AdCallbacks {
    @objc optional func onStartLoading(_ style: ADStyle)      // Loading started
    @objc optional func onLoadSuccess(_ style: ADStyle)       // Loading successful
    @objc optional func onLoadFailed(_ style: ADStyle, error: Error?)  // Loading failed
    @objc optional func onShowSuccess(_ style: ADStyle)       // Display successful
    @objc optional func onShowFailed(_ style: ADStyle, error: Error?)  // Display failed
    @objc optional func onGetAdReward(_ style: ADStyle)       // Reward earned
    @objc optional func onAdClick(_ style: ADStyle)           // Ad clicked
    @objc optional func onAdClose(_ style: ADStyle)           // Ad closed
}
```

### Callback Flow

```
User Action → onStartLoading → onLoadSuccess → onShowSuccess → onAdClose
     ↓              ↓              ↓              ↓            ↓
  Request Ad    Loading Ad    Ad Ready     Show Ad      Ad Complete
```

### Error Handling

```swift
extension AdManager {
    
    func handleAdError(_ error: Error?, style: ADStyle) {
        guard let error = error else { return }
        
        switch error {
        case let initError as InitError:
            handleInitError(initError, style: style)
        case let adError as AdError:
            handleAdError(adError, style: style)
        default:
            print("Unknown error: \(error.localizedDescription)")
        }
    }
    
    private func handleInitError(_ error: InitError, style: ADStyle) {
        switch error {
        case .serviceInitFailed(let message):
            print("Service initialization failed: \(message)")
        case .storageInitFailed(let message):
            print("Storage initialization failed: \(message)")
        case .alreadyInitialized:
            print("SDK already initialized")
        }
    }
    
    private func handleAdError(_ error: AdError, style: ADStyle) {
        switch error {
        case .noFill:
            print("No ad fill available for: \(style)")
        case .networkError:
            print("Network error for: \(style)")
        case .timeout:
            print("Ad request timeout for: \(style)")
        }
    }
}
```

## 🎯 Best Practices

### 1. Ad Placement Strategy

```swift
class AdPlacementStrategy {
    
    // Natural break points
    func showInterstitialAtLevelComplete() {
        GrowthKit.showAd(with: .inserted)
    }
    
    // User-initiated actions
    func showRewardedForExtraLives() {
        GrowthKit.showAd(with: .rewarded)
    }
    
    // App lifecycle
    func showAppOpenOnResume() {
        GrowthKit.showAd(with: .appOpen)
    }
}
```

### 2. User Experience Optimization

```swift
class UserExperienceManager {
    
    // Avoid showing ads too frequently
    private let minimumAdInterval: TimeInterval = 60
    
    func showAdWithUserExperienceCheck(_ style: ADStyle) {
        guard shouldShowAd(style) else {
            print("Skipping ad for better user experience")
            return
        }
        
        GrowthKit.showAd(with: style)
    }
    
    private func shouldShowAd(_ style: ADStyle) -> Bool {
        // Check user engagement, time since last ad, etc.
        return true
    }
}
```

### 3. Revenue Optimization

```swift
class RevenueOptimizer {
    
    // A/B test different ad placements
    func showOptimizedAd(_ style: ADStyle, variant: String) {
        // Track variant performance
        Analytics.track("ad_variant", parameters: ["style": style.rawValue, "variant": variant])
        
        GrowthKit.showAd(with: style)
    }
    
    // Monitor ad performance
    func trackAdPerformance(_ style: ADStyle, metrics: [String: Any]) {
        Analytics.track("ad_performance", parameters: [
            "style": style.rawValue,
            "metrics": metrics
        ])
    }
}
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Ads Not Loading

**Symptoms:**
- `onLoadFailed` callback triggered
- No ads displayed

**Solutions:**
- Check network connectivity
- Verify SDK initialization
- Ensure proper configuration
- Check ad network settings

#### 2. Ads Not Displaying

**Symptoms:**
- `onShowFailed` callback triggered
- Ads load but don't show

**Solutions:**
- Check view controller hierarchy
- Ensure proper window setup
- Verify ad network integration
- Check frequency capping

#### 3. Low Fill Rate

**Symptoms:**
- Many `onLoadFailed` callbacks
- Poor monetization

**Solutions:**
- Add more ad networks
- Optimize ad placement
- Improve user targeting
- Check ad network health

### Debug Tools

```swift
class AdDebugTools {
    
    // Enable comprehensive logging
    func enableDebugMode() {
        GrowthKit.isLoggingEnabled = true
        GrowthKit.shared.showAdDebugger()
    }
    
    // Test ad flow
    func testAdFlow(_ style: ADStyle) {
        print("Testing ad flow for: \(style)")
        
        let testCallbacks = TestAdCallbacks()
        GrowthKit.showAd(with: style, callbacks: testCallbacks)
    }
}

class TestAdCallbacks: NSObject, AdCallbacks {
    
    func onStartLoading(_ style: ADStyle) {
        print("🔄 Test: Ad loading started")
    }
    
    func onLoadSuccess(_ style: ADStyle) {
        print("✅ Test: Ad loaded successfully")
    }
    
    func onLoadFailed(_ style: ADStyle, error: Error?) {
        print("❌ Test: Ad load failed - \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func onShowSuccess(_ style: ADStyle) {
        print("🎯 Test: Ad shown successfully")
    }
    
    func onShowFailed(_ style: ADStyle, error: Error?) {
        print("💥 Test: Ad show failed - \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func onGetAdReward(_ style: ADStyle) {
        print("🎁 Test: User earned reward")
    }
    
    func onAdClick(_ style: ADStyle) {
        print("👆 Test: Ad clicked")
    }
    
    func onAdClose(_ style: ADStyle) {
        print("🔒 Test: Ad closed")
    }
}
```

## 📱 Platform-Specific Considerations

### iOS Integration

- **View Controller Hierarchy** - Ensure proper presentation
- **Window Management** - Required for ad mediation
- **Background App Refresh** - Affects ad loading
- **Privacy Permissions** - ATT and IDFA requirements

### Unity Integration

- **Native Bridge** - Proper callback handling
- **View Management** - SDK view integration
- **Lifecycle Management** - App state handling
- **Performance Optimization** - Memory management

## 📞 Support

For advertising-related questions:

- Check the [Integration Guide](INTEGRATION_GUIDE.md)
- Review [API Reference](API_REFERENCE.md)
- Contact support: [support@shuge.com](mailto:support@shuge.com)

---

**Need help with advertising?** Check our [FAQ](FAQ.md) or [contact support](mailto:support@shuge.com).
