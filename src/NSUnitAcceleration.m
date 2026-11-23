#import <Foundation/NSUnitAcceleration.h>
#import <Foundation/NSUnitConverterLinear.h>
#import <Foundation/NSString.h>
#import <dispatch/dispatch.h>

/* Declared by the SDK's NSUnit.h; Darling's stub headers do not list them yet. */
@interface NSUnitConverterLinear (DarlingSDKInit)
- (instancetype)initWithCoefficient:(double)coefficient;
@end
@interface NSDimension (DarlingSDKInit)
- (instancetype)initWithSymbol:(NSString *)symbol converter:(NSUnitConverter *)converter;
@end

static NSUnitAcceleration *NSUnitAccelerationMake(NSString *symbol, double coefficient)
{
    NSUnitConverterLinear *converter = [[NSUnitConverterLinear alloc] initWithCoefficient:coefficient];
    NSUnitAcceleration *unit = [[NSUnitAcceleration alloc] initWithSymbol:symbol converter:converter];
    [converter release];
    return unit;
}

@implementation NSUnitAcceleration

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (instancetype)baseUnit
{
    return [self metersPerSecondSquared];
}

+ (NSUnitAcceleration *)metersPerSecondSquared
{
    static NSUnitAcceleration *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitAccelerationMake(@"m/s²", 1.0);
    });
    return unit;
}

+ (NSUnitAcceleration *)gravity
{
    static NSUnitAcceleration *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitAccelerationMake(@"g’s", 9.81);
    });
    return unit;
}

@end
