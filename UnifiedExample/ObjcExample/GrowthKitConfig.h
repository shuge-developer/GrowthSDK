//
//  GrowthKitConfig.h
//  ObjcExample
//
//  Created by arvin on 2025/8/7.
//

#ifndef GrowthKitConfig_h
#define GrowthKitConfig_h

#import <Foundation/Foundation.h>

// MARK: -
static NSString * const kGrowthKitAppId = @"1937764714536771585";
static NSString * const kGrowthKitBundleName = @"com.shuge.game.tongyong";
static NSString * const kGrowthKitBaseUrl = @"http://192.168.50.241:2888";
static NSString * const kGrowthKitPublicKey = @"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAk7vrnUKeb6Ky1h/rigkTWQzSURT8hGL6YujadShx3aL3WmfAR6DvSWHslkbIjbRUJWvZTrIHMB8slooq1LEDp28eWzGjK1C95bVX/S6GyisONAAd1vseRBi/BTQQFkanskLDxjfzl+bkGBpd59xfr16zys9MbvcuN3zzEy9v56xZYXWn6r6Aca7+afBsH4hQc3Deo95bm2Q6EVM2l1OLOAX2GWqqtslICY/h8EZSCtFWs4e8r/BR+/bcYtTOu+D43gNDZ5IBjwcTtFhrxbOKda/g8w6nbXGAECErEY4+Udh71VEW/N2N88vbwq7b8CGC7/GsPsyRs+5uTV2md4GJeQIDAQAB";
static NSString * const kGrowthKitAppKey = @"VIZFwZVGXUuefGUV";
static NSString * const kGrowthKitAppIv = @"YjPBSAtcLZghUVEq";

// MARK: -
@interface GrowthKitConfig : NSObject

+ (id)defaultConfig;

+ (id)configWithAppId:(NSString *)appId
           bundleName:(NSString *)bundleName
              baseUrl:(NSString *)baseUrl
            publicKey:(NSString *)publicKey
               appKey:(NSString *)appKey
                appIv:(NSString *)appIv;

@end

#endif /* GrowthKitConfig_h */
