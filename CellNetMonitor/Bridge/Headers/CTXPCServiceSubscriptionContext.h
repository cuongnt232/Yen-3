#import <Foundation/Foundation.h>

@interface CTXPCServiceSubscriptionContext : NSObject
@property (nonatomic, readonly) long long slotID;
+ (instancetype)contextWithSlot:(int)slot;
+ (instancetype)contextWithServiceDescriptor:(id)descriptor;
@end
