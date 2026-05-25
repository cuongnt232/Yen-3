#import <Foundation/Foundation.h>

@interface CTCellIdInfo : NSObject
@property (nonatomic, readonly) NSNumber *cellId;
@property (nonatomic, readonly) NSNumber *baseId;
+ (instancetype)cellIdInfoFromCellId:(unsigned long long)cellId baseId:(int)baseId;
@end
