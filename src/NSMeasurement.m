#import <Foundation/NSMeasurement.h>
#import <Foundation/NSUnit.h>
#import <Foundation/NSDimension.h>
#import <Foundation/NSUnitConverter.h>
#import <Foundation/NSException.h>
#import <objc/runtime.h>

@interface NSUnitConverter (NSMeasurementConversion)
- (double)baseUnitValueFromValue:(double)value;
- (double)valueFromBaseUnitValue:(double)value;
@end

@interface NSMeasurement ()
- (NSUnit *)unit;
- (instancetype)initWithDoubleValue:(double)value unit:(NSUnit *)unit;
- (NSMeasurement *)measurementByConvertingToUnit:(NSUnit *)unit;
@end

@interface _NSMeasurementStorage : NSObject
{
@public
    NSUnit *unit;
    double doubleValue;
}
- (instancetype)initWithDoubleValue:(double)value unit:(NSUnit *)measurementUnit;
@end

@implementation _NSMeasurementStorage

- (instancetype)initWithDoubleValue:(double)value unit:(NSUnit *)measurementUnit
{
    self = [super init];
    if (self != nil)
    {
        doubleValue = value;
        unit = [measurementUnit retain];
    }
    return self;
}

- (void)dealloc
{
    [unit release];
    [super dealloc];
}

@end

static char NSMeasurementStorageKey;

static _NSMeasurementStorage *measurementStorage(id measurement)
{
    return objc_getAssociatedObject(measurement, &NSMeasurementStorageKey);
}

static id unitConverter(NSUnit *unit)
{
    if (unit == nil)
    {
        return nil;
    }
    Ivar converterIvar = class_getInstanceVariable([unit class], "_dimensionConverter");
    if (converterIvar == NULL)
    {
        converterIvar = class_getInstanceVariable([unit class], "_converter");
    }
    return converterIvar == NULL ? nil : object_getIvar(unit, converterIvar);
}

static BOOL converterImplements(id converter, SEL selector)
{
    return converter != nil && class_getInstanceMethod([converter class], selector) != NULL;
}

@implementation NSMeasurement

- (double)doubleValue
{
    _NSMeasurementStorage *storage = measurementStorage(self);
    return storage == nil ? 0.0 : storage->doubleValue;
}

- (NSUnit *)unit
{
    _NSMeasurementStorage *storage = measurementStorage(self);
    return storage == nil ? nil : storage->unit;
}

- (instancetype)initWithDoubleValue:(double)value unit:(NSUnit *)unit
{
    if (unit == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"A measurement requires a unit"];
        [self release];
        return nil;
    }
    self = [super init];
    if (self != nil)
    {
        _NSMeasurementStorage *storage = [[_NSMeasurementStorage alloc] initWithDoubleValue:value unit:unit];
        objc_setAssociatedObject(self, &NSMeasurementStorageKey, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [storage release];
    }
    return self;
}

- (NSMeasurement *)measurementByConvertingToUnit:(NSUnit *)unit
{
    if (unit == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"A target unit is required for conversion"];
        return nil;
    }

    _NSMeasurementStorage *storage = measurementStorage(self);
    double value = storage == nil ? 0.0 : storage->doubleValue;
    id originalUnit = storage == nil ? nil : storage->unit;
    double convertedValue = value;
    if (unit != originalUnit)
    {
        if (originalUnit == nil || [unit class] != [originalUnit class])
        {
            [NSException raise:NSInvalidArgumentException format:@"Cannot convert a measurement between different unit dimensions"];
            return nil;
        }

        id sourceConverter = unitConverter(originalUnit);
        id targetConverter = unitConverter(unit);
        SEL toBase = @selector(baseUnitValueFromValue:);
        SEL fromBase = @selector(valueFromBaseUnitValue:);
        if (!converterImplements(sourceConverter, toBase) || !converterImplements(targetConverter, fromBase))
        {
            [NSException raise:NSInvalidArgumentException format:@"The unit converters do not provide conversion behavior"];
            return nil;
        }

        double baseValue = [sourceConverter baseUnitValueFromValue:value];
        convertedValue = [targetConverter valueFromBaseUnitValue:baseValue];
    }

    NSMeasurement *measurement = [[[self class] alloc] initWithDoubleValue:convertedValue unit:unit];
    return [measurement autorelease];
}

@end
