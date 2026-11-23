#import <Foundation/NSUnitLength.h>
#import <Foundation/NSUnitConverterLinear.h>
#import <dispatch/dispatch.h>

static NSUnitLength *NSUnitLengthMake(NSString *symbol, double coefficient)
{
    NSUnitConverterLinear *converter = [[NSUnitConverterLinear alloc] initWithCoefficient:coefficient];
    NSUnitLength *unit = [[NSUnitLength alloc] initWithSymbol:symbol converter:converter];
    [converter release];
    return unit;
}

@implementation NSUnitLength

+ (NSUnitLength *)centimeters
{
    static NSUnitLength *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ unit = NSUnitLengthMake(@"cm", 0.01); });
    return unit;
}

+ (NSUnitLength *)feet
{
    static NSUnitLength *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ unit = NSUnitLengthMake(@"ft", 0.3048); });
    return unit;
}

+ (NSUnitLength *)inches
{
    static NSUnitLength *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ unit = NSUnitLengthMake(@"in", 0.0254); });
    return unit;
}

+ (NSUnitLength *)meters
{
    static NSUnitLength *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ unit = NSUnitLengthMake(@"m", 1.0); });
    return unit;
}

+ (NSUnitLength *)miles
{
    static NSUnitLength *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ unit = NSUnitLengthMake(@"mi", 1609.344); });
    return unit;
}

+ (NSUnitLength *)millimeters
{
    static NSUnitLength *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ unit = NSUnitLengthMake(@"mm", 0.001); });
    return unit;
}

+ (NSUnitLength *)yards
{
    static NSUnitLength *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ unit = NSUnitLengthMake(@"yd", 0.9144); });
    return unit;
}

@end
