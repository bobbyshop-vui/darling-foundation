#import <Foundation/NSUnitConverterLinear.h>

@implementation NSUnitConverterLinear

- (instancetype)initWithCoefficient:(double)coefficient
{
    return [self initWithCoefficient:coefficient constant:0.0];
}

- (instancetype)initWithCoefficient:(double)coefficient constant:(double)constant
{
    self = [super init];
    if (self) {
        _coefficient = coefficient;
        _constant = constant;
    }
    return self;
}

- (double)coefficient
{
    return _coefficient;
}

- (double)constant
{
    return _constant;
}

- (double)baseUnitValueFromValue:(double)value
{
    return _coefficient * value + _constant;
}

- (double)valueFromBaseUnitValue:(double)baseUnitValue
{
    return (baseUnitValue - _constant) / _coefficient;
}

@end
