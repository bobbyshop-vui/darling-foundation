#import <Foundation/NSUnitDuration.h>
#import <Foundation/NSUnitConverterLinear.h>
#import <dispatch/dispatch.h>

static NSUnitDuration *NSUnitDurationMake(NSString *symbol, double coefficient)
{
    NSUnitConverterLinear *converter = [[NSUnitConverterLinear alloc] initWithCoefficient:coefficient];
    NSUnitDuration *unit = [[NSUnitDuration alloc] initWithSymbol:symbol converter:converter];
    [converter release];
    return unit;
}

@implementation NSUnitDuration

+ (NSUnitDuration *)minutes
{
    static NSUnitDuration *unit;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unit = NSUnitDurationMake(@"min", 60.0);
    });
    return unit;
}

@end
