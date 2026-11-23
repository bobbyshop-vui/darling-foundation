#import <Foundation/NSDimension.h>

NS_ASSUME_NONNULL_BEGIN

/* Base unit - newtonsPerMetersSquared (equivalent to 1 pascal) */
@interface NSUnitPressure : NSDimension <NSSecureCoding>

+ (NSUnitPressure *)newtonsPerMetersSquared;
+ (NSUnitPressure *)gigapascals;
+ (NSUnitPressure *)megapascals;
+ (NSUnitPressure *)kilopascals;
+ (NSUnitPressure *)hectopascals;
+ (NSUnitPressure *)inchesOfMercury;
+ (NSUnitPressure *)bars;
+ (NSUnitPressure *)millibars;
+ (NSUnitPressure *)millimetersOfMercury;
+ (NSUnitPressure *)poundsForcePerSquareInch;

@end

NS_ASSUME_NONNULL_END
