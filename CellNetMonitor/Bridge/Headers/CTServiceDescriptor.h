#import <Foundation/Foundation.h>

@interface CTServiceDescriptor : NSObject
@property (nonatomic, readonly) NSString *identifier;
+ (instancetype)descriptorWithSubscriptionContext:(id)context;
+ (instancetype)telephonyDescriptorWithInstance:(id)instance;
@end
