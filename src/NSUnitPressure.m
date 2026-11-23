#import <Foundation/NSUnitPressure.h>
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

static NSUnitPressure *NSUnitPressureMake(NSString *symbol, double coefficient)
{
    NSUnitConverterLinear *converter = [[NSUnitConverterLinear alloc] initWithCoefficient:coefficient];
    NSUnitPressure *unit = [[NSUnitPressure alloc] initWithSymbol:symbol converter:converter];
    [converter release];
    return unit;
}

@implementation NSUnitPressure

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (instancetype)baseUnit
{
    return [self newtonsPerMetersSquared];
}

+ (NSUnitPressure *)newtonsPerMetersSquared
{
    static NSUnitPressure *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitPressureMake(@"N/m\u00B2", 1.0);
    });
    return unit;
}

+ (NSUnitPressure *)gigapascals
{
    static NSUnitPressure *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitPressureMake(@"GPa", 1000000000.0);
    });
    return unit;
}

+ (NSUnitPressure *)megapascals
{
    static NSUnitPressure *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitPressureMake(@"MPa", 1000000.0);
    });
    return unit;
}

+ (NSUnitPressure *)kilopascals
{
    static NSUnitPressure *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitPressureMake(@"kPa", 1000.0);
    });
    return unit;
}

+ (NSUnitPressure *)hectopascals
{
    static NSUnitPressure *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitPressureMake(@"hPa", 100.0);
    });
    return unit;
}

+ (NSUnitPressure *)inchesOfMercury
{
    static NSUnitPressure *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitPressureMake(@"inHg", 3386.39);
    });
    return unit;
}

+ (NSUnitPressure *)bars
{
    static NSUnitPressure *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitPressureMake(@"bar", 100000.0);
    });
    return unit;
}

+ (NSUnitPressure *)millibars
{
    static NSUnitPressure *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitPressureMake(@"mbar", 100.0);
    });
    return unit;
}

+ (NSUnitPressure *)millimetersOfMercury
{
    static NSUnitPressure *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitPressureMake(@"mmHg", 133.322);
    });
    return unit;
}

+ (NSUnitPressure *)poundsForcePerSquareInch
{
    static NSUnitPressure *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitPressureMake(@"psi", 6894.76);
    });
    return unit;
}

@end
