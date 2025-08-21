# GrowthSDK Unity Integration Guide

Specialized guide for Unity game developers integrating GrowthSDK.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Unity Project Setup](#unity-project-setup)
3. [iOS Integration](#ios-integration)
4. [Native Bridge Implementation](#native-bridge-implementation)
5. [Ad Integration](#ad-integration)
6. [View Management](#view-management)
7. [Testing & Debugging](#testing--debugging)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

## 🎮 Overview

GrowthSDK provides seamless integration with Unity games, offering:

- **Native iOS Integration** - Full access to iOS features
- **Ad Management** - Unified advertising solution
- **View Management** - Native UI integration
- **Performance Optimization** - Optimized for mobile gaming
- **Cross-Platform Support** - Unity + iOS native bridge

## 🚀 Unity Project Setup

### 1. Unity Export Settings

1. **Build Settings**
   - Platform: iOS
   - Target Device: iPhone + iPad
   - Architecture: ARM64
   - Scripting Backend: IL2CPP
   - Target minimum iOS Version: 14.0

2. **Player Settings**
   - Bundle Identifier: Set your app bundle ID
   - Version: Set app version
   - Target Device: iPhone + iPad
   - Scripting Define Symbols: Add `UNITY_IOS`

3. **Export Project**
   - File → Build Settings → iOS → Build
   - Choose output directory
   - Export as Xcode project

### 2. Unity Scripts

Create a Unity script to handle SDK communication:

```csharp
using UnityEngine;
using System.Runtime.InteropServices;

public class GrowthSDKManager : MonoBehaviour
{
    // Native method declarations
    [DllImport("__Internal")]
    private static extern void OnAdShow(string adType);
    
    [DllImport("__Internal")]
    private static extern void OnSDKInitialized();
    
    // Unity events
    public static event System.Action<string> OnAdShowRequested;
    public static event System.Action OnSDKReady;
    
    // Singleton pattern
    public static GrowthSDKManager Instance { get; private set; }
    
    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }
    
    // Public methods for Unity
    public void ShowRewardedAd()
    {
        #if UNITY_IOS && !UNITY_EDITOR
            OnAdShow("0");
        #else
            Debug.Log("Rewarded ad requested (Editor/Android)");
        #endif
    }
    
    public void ShowInterstitialAd()
    {
        #if UNITY_IOS && !UNITY_EDITOR
            OnAdShow("1");
        #else
            Debug.Log("Interstitial ad requested (Editor/Android)");
        #endif
    }
    
    public void ShowAppOpenAd()
    {
        #if UNITY_IOS && !UNITY_EDITOR
            OnAdShow("2");
        #else
            Debug.Log("App open ad requested (Editor/Android)");
        #endif
    }
    
    public void ShowAdDebugger()
    {
        #if UNITY_IOS && !UNITY_EDITOR
            OnAdShow("3");
        #else
            Debug.Log("Ad debugger requested (Editor/Android)");
        #endif
    }
    
    // Called from native iOS
    public void OnNativeAdShowRequested(string adType)
    {
        Debug.Log($"Native ad request: {adType}");
        OnAdShowRequested?.Invoke(adType);
    }
    
    public void OnNativeSDKReady()
    {
        Debug.Log("Native SDK is ready");
        OnSDKReady?.Invoke();
    }
}
```

## 📱 iOS Integration

### 1. Xcode Project Setup

1. **Import Unity Project**
   - Open exported Xcode project
   - Ensure `UnityFramework.framework` is linked
   - Set "Embed & Sign" for UnityFramework

2. **Add GrowthSDK**
   - Add GrowthSDK via CocoaPods or manual integration
   - Link required frameworks

3. **Configure Info.plist**
   - Add required permissions (see [Requirements Guide](REQUIREMENTS.md))
   - Configure SKAdNetwork
   - Set AdMob App ID

### 2. Unity Call Provider

Create the native bridge for Unity communication:

```objc
// UnityCallProvider.h
#import <Foundation/Foundation.h>
#import <UnityFramework/NativeCallProxy.h>

NS_ASSUME_NONNULL_BEGIN

@interface UnityCallProvider : NSObject<NativeCallable>

@property(class, nonatomic, readonly) UnityCallProvider *sharedInstance NS_SWIFT_NAME(shared);

@end

NS_ASSUME_NONNULL_END
```

```objc
// UnityCallProvider.m
#import "UnityCallProvider.h"
#import <GrowthSDK/GrowthSDK-Swift.h>

@implementation UnityCallProvider

static UnityCallProvider *_instance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

#pragma mark - NativeCallable
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

### 3. AppDelegate Integration

```objc
// AppDelegate.m
#import <GrowthSDK/GrowthSDK-Swift.h>
#import "UnityCallProvider.h"

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

    NetworkConfig *config = [[NetworkConfig alloc] initWithServiceId:@"unity_game_app"
                                                         bundleName:@"com.example.unitygame"
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
                // Notify Unity that SDK is ready
                UnitySendMessage("GrowthSDKManager", "OnNativeSDKReady", "");
            }
        });
    }];
}
```

## 🔗 Native Bridge Implementation

### 1. Unity Message Sending

```csharp
// Unity to Native communication
public class UnityToNativeBridge : MonoBehaviour
{
    public void SendAdRequest(string adType)
    {
        #if UNITY_IOS && !UNITY_EDITOR
            // Send message to native iOS
            OnAdShow(adType);
        #else
            Debug.Log($"Ad request sent: {adType} (Editor/Android)");
        #endif
    }
    
    public void SendCustomMessage(string message)
    {
        #if UNITY_IOS && !UNITY_EDITOR
            // Add more native methods as needed
            Debug.Log($"Custom message: {message}");
        #endif
    }
}
```

### 2. Native to Unity Communication

```objc
// Native to Unity communication
@implementation UnityCallProvider

- (void)notifyUnity:(NSString *)gameObject method:(NSString *)method message:(NSString *)message {
    UnitySendMessage(gameObject.UTF8String, method.UTF8String, message.UTF8String);
}

- (void)onAdShow:(nullable NSString *)json {
    NSInteger showType = [json integerValue];
    
    // Notify Unity about ad request
    [self notifyUnity:@"GrowthSDKManager" method:@"OnNativeAdShowRequested" message:json];
    
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

### 3. Bidirectional Communication

```csharp
// Enhanced Unity manager with bidirectional communication
public class EnhancedGrowthSDKManager : MonoBehaviour
{
    [System.Serializable]
    public class AdEvent
    {
        public string eventType;
        public string adType;
        public string message;
    }
    
    public static event System.Action<AdEvent> OnAdEvent;
    
    // Unity to Native
    public void RequestAd(string adType)
    {
        #if UNITY_IOS && !UNITY_EDITOR
            OnAdShow(adType);
        #else
            Debug.Log($"Ad request: {adType}");
        #endif
    }
    
    // Native to Unity
    public void OnNativeAdEvent(string eventData)
    {
        try
        {
            AdEvent adEvent = JsonUtility.FromJson<AdEvent>(eventData);
            OnAdEvent?.Invoke(adEvent);
            
            Debug.Log($"Ad event: {adEvent.eventType} - {adEvent.adType}");
        }
        catch (System.Exception e)
        {
            Debug.LogError($"Failed to parse ad event: {e.Message}");
        }
    }
    
    // SDK Status
    public void OnSDKStatusChanged(string status)
    {
        Debug.Log($"SDK status: {status}");
    }
}
```

## 📱 Ad Integration

### 1. Unity Ad Manager

```csharp
public class UnityAdManager : MonoBehaviour
{
    [Header("Ad Settings")]
    public float minAdInterval = 30f;
    public bool enableRewardedAds = true;
    public bool enableInterstitialAds = true;
    public bool enableAppOpenAds = true;
    
    private float lastAdTime;
    
    private void Start()
    {
        // Subscribe to SDK events
        EnhancedGrowthSDKManager.OnAdEvent += HandleAdEvent;
        EnhancedGrowthSDKManager.OnSDKReady += OnSDKReady;
    }
    
    private void OnDestroy()
    {
        // Unsubscribe from events
        EnhancedGrowthSDKManager.OnAdEvent -= HandleAdEvent;
        EnhancedGrowthSDKManager.OnSDKReady -= OnSDKReady;
    }
    
    private void OnSDKReady()
    {
        Debug.Log("SDK is ready, ads can be shown");
    }
    
    private void HandleAdEvent(AdEvent adEvent)
    {
        switch (adEvent.eventType)
        {
            case "ad_loaded":
                Debug.Log($"Ad loaded: {adEvent.adType}");
                break;
            case "ad_shown":
                Debug.Log($"Ad shown: {adEvent.adType}");
                lastAdTime = Time.time;
                break;
            case "ad_failed":
                Debug.Log($"Ad failed: {adEvent.adType} - {adEvent.message}");
                break;
            case "reward_earned":
                Debug.Log($"Reward earned from: {adEvent.adType}");
                GrantReward(adEvent.adType);
                break;
        }
    }
    
    // Public methods for game integration
    public void ShowRewardedAd()
    {
        if (!enableRewardedAds) return;
        
        if (CanShowAd())
        {
            EnhancedGrowthSDKManager.Instance.RequestAd("0");
        }
        else
        {
            Debug.Log("Ad cooldown active");
        }
    }
    
    public void ShowInterstitialAd()
    {
        if (!enableInterstitialAds) return;
        
        if (CanShowAd())
        {
            EnhancedGrowthSDKManager.Instance.RequestAd("1");
        }
        else
        {
            Debug.Log("Ad cooldown active");
        }
    }
    
    public void ShowAppOpenAd()
    {
        if (!enableAppOpenAds) return;
        
        EnhancedGrowthSDKManager.Instance.RequestAd("2");
    }
    
    private bool CanShowAd()
    {
        return Time.time - lastAdTime >= minAdInterval;
    }
    
    private void GrantReward(string adType)
    {
        switch (adType)
        {
            case "0": // Rewarded
                // Grant game reward
                GameManager.Instance.AddExtraLives(1);
                break;
        }
    }
}
```

### 2. Game Integration

```csharp
// Example game integration
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }
    
    [Header("Game Settings")]
    public int extraLives = 3;
    public int currentLevel = 1;
    
    private UnityAdManager adManager;
    
    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
        
        adManager = FindObjectOfType<UnityAdManager>();
    }
    
    // Game events that trigger ads
    public void OnLevelComplete()
    {
        currentLevel++;
        
        // Show interstitial ad at level completion
        if (adManager != null)
        {
            adManager.ShowInterstitialAd();
        }
        
        // Continue to next level
        LoadNextLevel();
    }
    
    public void OnPlayerDeath()
    {
        extraLives--;
        
        if (extraLives <= 0)
        {
            // Game over - show rewarded ad for extra life
            if (adManager != null)
            {
                adManager.ShowRewardedAd();
            }
        }
    }
    
    public void AddExtraLives(int count)
    {
        extraLives += count;
        Debug.Log($"Extra lives added: {count}. Total: {extraLives}");
    }
    
    private void LoadNextLevel()
    {
        Debug.Log($"Loading level: {currentLevel}");
        // Level loading logic
    }
}
```

## 🖼️ View Management

### 1. SDK View Integration

```objc
// View management in UnityCallProvider
@implementation UnityCallProvider

- (void)showSDKView:(NSString *)viewType {
    if ([viewType isEqualToString:@"debugger"]) {
        [[GrowthKit shared] showAdDebugger];
    } else if ([viewType isEqualToString:@"settings"]) {
        // Show SDK settings view
        [self showSDKSettings];
    }
}

- (void)showSDKSettings {
    // Create and present SDK settings view
    UIViewController *settingsVC = [GrowthKit createControllerWith:nil];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:settingsVC animated:YES completion:nil];
}

@end
```

### 2. Unity View Integration

```csharp
public class SDKViewManager : MonoBehaviour
{
    public void ShowDebugger()
    {
        #if UNITY_IOS && !UNITY_EDITOR
            // Call native method to show debugger
            OnAdShow("3");
        #else
            Debug.Log("Debugger requested (Editor/Android)");
        #endif
    }
    
    public void ShowSettings()
    {
        #if UNITY_IOS && !UNITY_EDITOR
            // Add native method for settings
            Debug.Log("Settings requested");
        #else
            Debug.Log("Settings requested (Editor/Android)");
        #endif
    }
}
```

## 🧪 Testing & Debugging

### 1. Unity Testing

```csharp
public class SDKTester : MonoBehaviour
{
    [Header("Test Controls")]
    public bool testRewardedAds = true;
    public bool testInterstitialAds = true;
    public bool testAppOpenAds = true;
    
    private UnityAdManager adManager;
    
    private void Start()
    {
        adManager = FindObjectOfType<UnityAdManager>();
    }
    
    private void Update()
    {
        // Test key bindings
        if (Input.GetKeyDown(KeyCode.R))
        {
            TestRewardedAd();
        }
        
        if (Input.GetKeyDown(KeyCode.I))
        {
            TestInterstitialAd();
        }
        
        if (Input.GetKeyDown(KeyCode.O))
        {
            TestAppOpenAd();
        }
        
        if (Input.GetKeyDown(KeyCode.D))
        {
            TestDebugger();
        }
    }
    
    private void TestRewardedAd()
    {
        if (testRewardedAds && adManager != null)
        {
            Debug.Log("Testing rewarded ad...");
            adManager.ShowRewardedAd();
        }
    }
    
    private void TestInterstitialAd()
    {
        if (testInterstitialAds && adManager != null)
        {
            Debug.Log("Testing interstitial ad...");
            adManager.ShowInterstitialAd();
        }
    }
    
    private void TestAppOpenAd()
    {
        if (testAppOpenAds && adManager != null)
        {
            Debug.Log("Testing app open ad...");
            adManager.ShowAppOpenAd();
        }
    }
    
    private void TestDebugger()
    {
        Debug.Log("Testing debugger...");
        FindObjectOfType<SDKViewManager>()?.ShowDebugger();
    }
}
```

### 2. Native Debugging

```objc
@implementation UnityCallProvider

- (void)enableDebugMode {
    // Enable SDK logging
    GrowthKit.isLoggingEnabled = YES;
    
    // Show debug panel
    [[GrowthKit shared] showAdDebugger];
    
    NSLog(@"Debug mode enabled");
}

- (void)testAdFlow:(NSString *)adType {
    NSLog(@"Testing ad flow for type: %@", adType);
    
    // Test ad display
    [self onAdShow:adType];
}

@end
```

## 🎯 Best Practices

### 1. Performance Optimization

```csharp
public class PerformanceOptimizer : MonoBehaviour
{
    [Header("Performance Settings")]
    public bool enableAdPreloading = true;
    public float preloadDelay = 5f;
    
    private void Start()
    {
        if (enableAdPreloading)
        {
            StartCoroutine(PreloadAds());
        }
    }
    
    private IEnumerator PreloadAds()
    {
        // Wait for SDK initialization
        yield return new WaitForSeconds(preloadDelay);
        
        // Preload ads in background
        StartCoroutine(PreloadAdsInBackground());
    }
    
    private IEnumerator PreloadAdsInBackground()
    {
        while (true)
        {
            // Preload ads every 30 seconds
            yield return new WaitForSeconds(30f);
            
            // This would call native preload methods
            Debug.Log("Preloading ads...");
        }
    }
}
```

### 2. Error Handling

```csharp
public class ErrorHandler : MonoBehaviour
{
    private void Start()
    {
        // Subscribe to ad events
        EnhancedGrowthSDKManager.OnAdEvent += HandleAdEvent;
    }
    
    private void HandleAdEvent(AdEvent adEvent)
    {
        if (adEvent.eventType == "ad_failed")
        {
            HandleAdFailure(adEvent);
        }
    }
    
    private void HandleAdFailure(AdEvent adEvent)
    {
        Debug.LogWarning($"Ad failed: {adEvent.adType} - {adEvent.message}");
        
        // Implement fallback logic
        switch (adEvent.adType)
        {
            case "0": // Rewarded
                // Show alternative reward method
                ShowAlternativeReward();
                break;
            case "1": // Interstitial
                // Skip ad, continue game
                ContinueGame();
                break;
        }
    }
    
    private void ShowAlternativeReward()
    {
        Debug.Log("Showing alternative reward method");
        // Implement alternative reward logic
    }
    
    private void ContinueGame()
    {
        Debug.Log("Continuing game without ad");
        // Continue game flow
    }
}
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Unity-Native Communication Issues

**Symptoms:**
- Unity methods not calling native code
- Native callbacks not reaching Unity

**Solutions:**
- Verify method signatures match exactly
- Check Unity object names and method names
- Ensure proper iOS build settings
- Test with simple string parameters first

#### 2. Ad Display Issues

**Symptoms:**
- Ads not showing in Unity
- Crashes when displaying ads

**Solutions:**
- Check SDK initialization
- Verify view controller hierarchy
- Ensure proper window setup
- Test with native iOS app first

#### 3. Performance Issues

**Symptoms:**
- Slow ad loading
- Memory leaks
- Frame rate drops

**Solutions:**
- Implement ad preloading
- Optimize ad frequency
- Monitor memory usage
- Use background loading

### Debug Checklist

- [ ] SDK properly initialized
- [ ] Unity methods calling native code
- [ ] Native callbacks reaching Unity
- [ ] Ad networks configured
- [ ] Permissions set correctly
- [ ] Info.plist configured
- [ ] Unity build settings correct
- [ ] Framework linking proper

## 📞 Support

For Unity integration questions:

- Check the [Integration Guide](INTEGRATION_GUIDE.md)
- Review [Advertising Guide](ADVERTISING_GUIDE.md)
- Contact support: [support@shuge.com](mailto:support@shuge.com)

---

**Need help with Unity integration?** Check our [FAQ](FAQ.md) or [contact support](mailto:support@shuge.com).
