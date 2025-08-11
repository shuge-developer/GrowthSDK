# GrowthSDK SDK Objective-C 集成指南

## 🎯 Objective-C 支持

GrowthSDK SDK 现在完全支持 Objective-C 项目，提供了与 Swift 相同的功能。

## 🚀 快速集成

### 1. 导入头文件

在你的 Objective-C 文件中导入 GrowthSDK：

```objc
#import <GrowthSDK/GrowthSDK-Swift.h>
```

**注意**：如果使用XCFramework，可能需要使用：
```objc
#import "GrowthSDK-Swift.h"
```

### 2. SDK 初始化

#### AppDelegate 中初始化

```objc
#import <GrowthSDK/GrowthSDK-Swift.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 在应用启动时尽早初始化GrowthSDK SDK
    [self initializeGrowthSDKSDK];
    
    return YES;
}

- (void)initializeGrowthSDKSDK {
    NSLog(@"[AppDelegate] 🚀 开始初始化GrowthSDK SDK");
    
    // 创建网络配置
    GrowthSDKNetworkConfig *config = [[GrowthSDKNetworkConfig alloc] 
        initWithAppid:@"your_app_id"
        bundleName:[[NSBundle mainBundle] bundleIdentifier] ?: @"com.example.objc"
        baseUrl:@"https://api.example.com"
        publicKey:@"your_public_key"
        appKey:@"your_app_key"
        appIv:@"your_app_iv"];
    
    // 初始化SDK
    [[GameWebWrapper shared] initializeWithConfig:config completion:^(BOOL success, NSString * _Nullable errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSLog(@"[AppDelegate] ✅ GrowthSDK SDK初始化成功");
            } else {
                NSLog(@"[AppDelegate] ❌ GrowthSDK SDK初始化失败: %@", errorMessage);
            }
        });
    }];
}

@end
```

### 3. Unity 集成

#### SceneDelegate 中设置根控制器

```objc
#import <GrowthSDK/GrowthSDK-Swift.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        
        // 创建窗口
        self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
        
        // 初始化Unity和GrowthSDK集成
        [self initializeUnityAndGrowthSDK];
    }
}

- (void)initializeUnityAndGrowthSDK {
    NSLog(@"[SceneDelegate] 🎮 开始初始化Unity和GrowthSDK集成");
    
    // 初始化Unity
    [[UnityManager shared] initializeUnityWithCompletion:^(UIViewController * _Nullable controller, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (controller) {
                NSLog(@"[SceneDelegate] ✅ Unity初始化成功");
                [self setupGrowthSDKBridge:controller];
            } else {
                NSLog(@"[SceneDelegate] ❌ Unity初始化失败: %@", error);
            }
        });
    }];
}

- (void)setupGrowthSDKBridge:(UIViewController *)unityController {
    NSLog(@"[SceneDelegate] 🔗 设置GrowthSDK桥接器");
    
    // 创建GrowthSDK桥接器作为根控制器
    GrowthSDKUIKitBridge *growthKitBridge = [[GrowthSDKUIKitBridge alloc] initWithUnityController:unityController];
    
    // 设置为根控制器
    self.window.rootViewController = growthKitBridge;
    [self.window makeKeyAndVisible];
    
    NSLog(@"[SceneDelegate] ✅ Unity + GrowthSDK集成完成");
}

@end
```

### 4. 自定义 UnityManager

如果你的 UnityManager 是 Objective-C 实现的，需要添加 Swift 桥接：

```objc
// UnityManager.h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UnityManager : NSObject

+ (instancetype)shared;
- (void)initializeUnityWithCompletion:(void(^)(UIViewController * _Nullable controller, NSError * _Nullable error))completion;

@end

// UnityManager.m
#import "UnityManager.h"
#import <UnityFramework/UnityFramework.h>

@implementation UnityManager

+ (instancetype)shared {
    static UnityManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UnityManager alloc] init];
    });
    return instance;
}

- (void)initializeUnityWithCompletion:(void(^)(UIViewController * _Nullable controller, NSError * _Nullable error))completion {
    // 你的Unity初始化逻辑
    // ...
    
    // 完成后调用回调
    if (completion) {
        completion(unityController, nil);
    }
}

@end
```

## 📱 API 参考

### GrowthSDKNetworkConfig

```objc
@interface GrowthSDKNetworkConfig : NSObject

@property (nonatomic, copy, readonly) NSString *appid;
@property (nonatomic, copy, readonly) NSString *bundleName;
@property (nonatomic, copy, readonly) NSString *baseUrl;
@property (nonatomic, copy, readonly) NSString *publicKey;
@property (nonatomic, copy, readonly) NSString *appKey;
@property (nonatomic, copy, readonly) NSString *appIv;

- (instancetype)initWithAppid:(NSString *)appid
                  bundleName:(NSString *)bundleName
                     baseUrl:(NSString *)baseUrl
                   publicKey:(NSString *)publicKey
                      appKey:(NSString *)appKey
                        appIv:(NSString *)appIv;

@end
```

### GameWebWrapper

```objc
@interface GameWebWrapper : NSObject

+ (instancetype)shared;
@property (nonatomic, readonly) BOOL isInitialized;

- (void)initializeWithConfig:(GrowthSDKNetworkConfig *)config 
                  completion:(void(^)(BOOL success, NSString * _Nullable errorMessage))completion;

@end
```

### GrowthSDKUIKitBridge

```objc
@interface GrowthSDKUIKitBridge : UIViewController

- (instancetype)initWithUnityController:(UIViewController *)unityController;

@end
```

## 🔧 配置说明

### 网络配置参数

```objc
GrowthSDKNetworkConfig *config = [[GrowthSDKNetworkConfig alloc] 
    initWithAppid:@"your_app_id"           // 应用ID
    bundleName:@"com.example.app"          // Bundle标识符
    baseUrl:@"https://api.example.com"    // API基础URL
    publicKey:@"your_public_key"          // 公钥
    appKey:@"your_app_key"                // 应用密钥
    appIv:@"your_app_iv"];                // 初始化向量
```

## 🏗️ XCFramework 构建

### 构建支持Objective-C的XCFramework

GrowthSDK SDK需要正确配置才能支持Objective-C调用。使用提供的构建脚本：

```bash
cd GrowthSDK
chmod +x build_xcframework.sh
./build_xcframework.sh
```

### 关键构建设置

确保XCFramework包含以下设置：

1. **DEFINES_MODULE = YES** - 启用模块定义
2. **SWIFT_INSTALL_OBJC_HEADER = YES** - 生成Swift桥接头文件
3. **SWIFT_OBJC_INTERFACE_HEADER_NAME = "GrowthSDK-Swift.h"** - 指定桥接头文件名
4. **BUILD_LIBRARY_FOR_DISTRIBUTION = YES** - 支持分发

### 模块定义文件

GrowthSDK SDK包含以下文件：

- `module.modulemap` - 模块定义
- `GrowthSDK.h` - Umbrella header
- `GrowthSDK-Swift.h` - 自动生成的Swift桥接头文件

## 🎉 优势

1. **完全兼容 Objective-C** - 所有API都支持OC调用
2. **与Swift版本功能一致** - 相同的功能和性能
3. **简单的集成流程** - 只需几行代码即可集成
4. **自动忽略安全间距** - UI布局完美，无留白
5. **根控制器设计** - 避免视图层级问题

## 📝 注意事项

1. **导入头文件** - 确保正确导入 `<GrowthSDK/GrowthSDK-Swift.h>` 或 `"GrowthSDK-Swift.h"`
2. **主线程回调** - 所有UI相关操作都在主线程执行
3. **内存管理** - 使用 ARC，无需手动管理内存
4. **错误处理** - 始终处理初始化失败的情况
5. **XCFramework版本** - 确保使用支持Objective-C的XCFramework版本

## 🔧 故障排除

### 常见问题

1. **'GrowthSDK-Swift.h' file not found**
   - 确保XCFramework正确添加到项目中
   - 检查Framework Search Paths设置
   - 尝试使用不同的导入语法

2. **编译错误**
   - 清理项目 (Product → Clean Build Folder)
   - 重新构建项目
   - 检查XCFramework是否支持Objective-C

3. **运行时错误**
   - 确保SDK在AppDelegate中正确初始化
   - 检查网络配置参数
   - 验证Unity集成

这个设计完全支持 Objective-C 项目，提供了与 Swift 版本相同的功能和体验！
