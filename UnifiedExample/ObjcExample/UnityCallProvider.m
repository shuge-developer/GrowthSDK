//
//  UnityCallProvider.m
//  ObjcExample
//
//  Created by arvin on 2025/8/21.
//

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
