//
//  UnityCallProvider.m
//  ObjcExample
//
//  Created by arvin on 2025/8/21.
//

#import "UnityCallProvider.h"
#import <GrowthSDK/GrowthSDK-Swift.h>

@interface UnityCallProvider ()<AdCallbacks>

@end

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
            [GrowthKit showAdWith:ADStyleRewarded callbacks:self];
            break;
        case 1:
            [GrowthKit showAdWith:ADStyleInserted callbacks:self];
            break;
        case 2:
            [GrowthKit showAdWith:ADStyleAppOpen callbacks:self];
            break;
        case 3:
            [[GrowthKit shared] showAdDebugger];
            break;
        default:
            break;
    }
}

#pragma mark - AdCallbacks
- (void)onStartLoading:(enum ADStyle)style {
    NSLog(@"[AD] %s: %zd", __func__, style);
}

- (void)onLoadSuccess:(enum ADStyle)style {
    NSLog(@"[AD] %s: %zd", __func__, style);
}

- (void)onLoadFailed:(enum ADStyle)style error:(NSError *)error {
    NSLog(@"[AD] %s: %zd, %@", __func__, style, error);
}

- (void)onShowSuccess:(enum ADStyle)style {
    NSLog(@"[AD] %s: %zd", __func__, style);
}

- (void)onShowFailed:(enum ADStyle)style error:(NSError *)error {
    NSLog(@"[AD] %s: %zd, %@", __func__, style, error);
}

- (void)onGetAdReward:(enum ADStyle)style {
    NSLog(@"[AD] %s: %zd", __func__, style);
}

- (void)onAdClick:(enum ADStyle)style {
    NSLog(@"[AD] %s: %zd", __func__, style);
}

- (void)onAdClose:(enum ADStyle)style {
    NSLog(@"[AD] %s: %zd", __func__, style);
}

@end
