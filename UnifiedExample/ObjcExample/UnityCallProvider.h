//
//  UnityCallProvider.h
//  ObjcExample
//
//  Created by arvin on 2025/8/21.
//

#import <Foundation/Foundation.h>
#import <UnityFramework/NativeCallProxy.h>

NS_ASSUME_NONNULL_BEGIN

@interface UnityCallProvider : NSObject<NativeCallable>

@property(class, nonatomic, readonly) UnityCallProvider *sharedInstance NS_SWIFT_NAME(shared);

@end

NS_ASSUME_NONNULL_END
