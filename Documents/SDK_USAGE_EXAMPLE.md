# GrowthSDK 使用示例

## SDK 初始化

```swift
import GrowthSDK

// 在应用启动时初始化SDK
let config = NetworkConfig(
    serviceId: "your_service_id",
    bundleName: "your_bundle_name", 
    serviceUrl: "https://your-api-url.com",
    serviceKey: "your_service_key",
    serviceIv: "your_service_iv",
    publicKey: "your_public_key"
)

GrowthKit.shared.initialize(with: config) { error in
    if let error = error {
        print("SDK初始化失败: \(error)")
    } else {
        print("SDK初始化成功")
    }
}
```

## 广告展示

### 1. 简单展示广告

```swift
// 展示激励广告
GrowthKit.showAd(with: .rewarded)

// 展示插屏广告  
GrowthKit.showAd(with: .inserted)

// 展示开屏广告
GrowthKit.showAd(with: .appOpen)
```

### 2. 带回调的广告展示

```swift
class AdManager: AdCallbacks {
    
    func showRewardedAd() {
        GrowthKit.showAd(with: .rewarded, callbacks: self)
    }
    
    // MARK: - AdCallbacks
    
    func onStartLoading() {
        print("广告开始加载")
    }
    
    func onLoadSuccess() {
        print("广告加载成功")
    }
    
    func onLoadFailed(_ error: Error?) {
        print("广告加载失败: \(error?.localizedDescription ?? "未知错误")")
    }
    
    func onShowSuccess() {
        print("广告展示成功")
    }
    
    func onShowFailed(_ error: Error?) {
        print("广告展示失败: \(error?.localizedDescription ?? "未知错误")")
    }
    
    func onAdClick() {
        print("广告被点击")
    }
    
    func onGetReward() {
        print("获得广告奖励")
    }
    
    func onClose() {
        print("广告关闭")
    }
}
```

### 3. Objective-C 使用示例

```objc
#import <GrowthSDK/GrowthSDK.h>

@interface AdViewController : UIViewController <AdCallbacks>
@end

@implementation AdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 展示激励广告
    [GrowthKit showAdWith:ADStyleRewarded callbacks:self];
}

#pragma mark - AdCallbacks

- (void)onStartLoading {
    NSLog(@"广告开始加载");
}

- (void)onLoadSuccess {
    NSLog(@"广告加载成功");
}

- (void)onLoadFailed:(NSError *)error {
    NSLog(@"广告加载失败: %@", error.localizedDescription);
}

- (void)onShowSuccess {
    NSLog(@"广告展示成功");
}

- (void)onShowFailed:(NSError *)error {
    NSLog(@"广告展示失败: %@", error.localizedDescription);
}

- (void)onGetReward {
    NSLog(@"获得广告奖励");
    // 给用户发放奖励
}

- (void)onClose {
    NSLog(@"广告关闭");
}

@end
```

## 广告类型说明

- `ADStyle.rewarded`: 激励视频广告，用户观看完整视频后可获得奖励
- `ADStyle.inserted`: 插屏广告，在应用场景切换时展示的全屏广告
- `ADStyle.appOpen`: 开屏广告，应用启动时展示的广告

## 注意事项

1. 请确保在SDK初始化完成后再调用广告展示方法
2. 广告回调方法都是可选的，可根据需要实现
3. 激励视频广告的奖励发放应在`onGetReward`回调中处理
4. 建议在广告展示失败时提供备用方案或重试机制
