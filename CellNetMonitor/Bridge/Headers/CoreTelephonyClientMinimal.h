#import <Foundation/Foundation.h>
#import "CTXPCServiceSubscriptionContext.h"
#import "CTServiceDescriptor.h"
#import "CTCellInfo.h"
#import "CTCellIdInfo.h"
#import "CTBandInfo.h"

@interface CoreTelephonyClient : NSObject
- (instancetype)init;
- (CTXPCServiceSubscriptionContext *)getPreferredDataSubscriptionContextSync:(NSError **)error;
- (CTCellIdInfo *)copyPublicCellId:(CTServiceDescriptor *)descriptor error:(NSError **)error;
- (void)copyCellInfo:(CTXPCServiceSubscriptionContext *)context
          completion:(void (^)(CTCellInfo *info, NSError *error))completion;
- (CTBandInfo *)getBandInfo:(CTXPCServiceSubscriptionContext *)context error:(NSError **)error API_AVAILABLE(ios(14.0));
- (NSString *)copyRadioAccessTechnology:(CTXPCServiceSubscriptionContext *)context error:(NSError **)error;
@end
