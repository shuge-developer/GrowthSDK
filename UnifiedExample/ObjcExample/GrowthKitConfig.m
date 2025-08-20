//
//  GrowthKitConfig.m
//  ObjcExample
//
//  Created by arvin on 2025/8/7.
//

#import "GrowthKitConfig.h"
#import <GrowthSDK/GrowthSDK-Swift.h>

@implementation GrowthKitConfig

+ (NSArray<ConfigKeyItem *> *)configKeyItems {
    return @[
        [[ConfigKeyItem alloc] initWithAdjustKey:@"ccs_ad_just_config"],
        [[ConfigKeyItem alloc] initWithConfigKey:@"ccs_sdk_config"],
        [[ConfigKeyItem alloc] initWithAdUnitKey:@"ccs_ad_config"]
    ];
}

+ (NetworkConfig *)defaultConfig {
    return [[NetworkConfig alloc] initWithServiceId:kGrowthKitAppId
                                         bundleName:kGrowthKitBundleName
                                         serviceUrl:kGrowthKitBaseUrl
                                         serviceKey:kGrowthKitAppKey
                                          serviceIv:kGrowthKitAppIv
                                          publicKey:kGrowthKitPublicKey
                                     configKeyItems:[self configKeyItems]
                                              other:nil];
}

+ (NetworkConfig *)configWithAppId:(NSString *)appId
                        bundleName:(NSString *)bundleName
                           baseUrl:(NSString *)baseUrl
                         publicKey:(NSString *)publicKey
                            appKey:(NSString *)appKey
                             appIv:(NSString *)appIv {
    
    return [[NetworkConfig alloc] initWithServiceId:appId
                                         bundleName:bundleName
                                         serviceUrl:baseUrl
                                         serviceKey:appKey
                                          serviceIv:appIv
                                          publicKey:publicKey
                                     configKeyItems:@[]
                                              other:nil];
}

@end
