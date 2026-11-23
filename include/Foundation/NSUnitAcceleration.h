#import <Foundation/NSDimension.h>

NS_ASSUME_NONNULL_BEGIN

/* Base unit - metersPerSecondSquared */
@interface NSUnitAcceleration : NSDimension <NSSecureCoding>

+ (NSUnitAcceleration *)metersPerSecondSquared;
+ (NSUnitAcceleration *)gravity;

@end

NS_ASSUME_NONNULL_END
