#import <Foundation/NSUnitConverter.h>

@implementation NSUnitConverter

- (double)baseUnitValueFromValue:(double)value
{
    return value;
}

- (double)valueFromBaseUnitValue:(double)baseUnitValue
{
    return baseUnitValue;
}

@end
