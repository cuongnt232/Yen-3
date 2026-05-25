#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CellProbeResult : NSObject
@property (nonatomic, copy, nullable) NSString *carrier;
@property (nonatomic, copy, nullable) NSString *mcc;
@property (nonatomic, copy, nullable) NSString *mnc;
@property (nonatomic, copy, nullable) NSString *radioAccessTechnology;
@property (nonatomic, copy, nullable) NSString *band;
@property (nonatomic, strong, nullable) NSNumber *cid;
@property (nonatomic, strong, nullable) NSNumber *enbid;
@property (nonatomic, strong, nullable) NSNumber *eci;
@property (nonatomic, strong, nullable) NSNumber *pci;
@property (nonatomic, copy, nullable) NSString *statusMessage;
@property (nonatomic, copy, nullable) NSString *rawCellInfo;
@end

@interface CellProbeService : NSObject
+ (instancetype)shared;
- (CellProbeResult *)fetchServingCellInfo;
@end

NS_ASSUME_NONNULL_END
