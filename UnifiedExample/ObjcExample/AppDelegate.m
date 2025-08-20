//
//  AppDelegate.m
//  ObjcExample
//
//  Created by arvin on 2025/8/7.
//

#import "AppDelegate.h"
#import <GrowthSDK/GrowthSDK-Swift.h>
#import "GrowthKitConfig.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initializeGrowthKitSDK: launchOptions];
    return YES;
}

- (void)initializeGrowthKitSDK:(NSDictionary *)launchOptions {
    NetworkConfig *config = [GrowthKitConfig defaultConfig];
    [[GrowthKit shared] initializeWith:config launchOptions:launchOptions completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"[app] SDK初始化失败: %@", error.localizedDescription);
            } else {
                NSLog(@"[app] SDK初始化成功");
            }
        });
    }];
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

@end
