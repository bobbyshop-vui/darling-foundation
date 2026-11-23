//
//  NSFormatter.m
//  Foundation
//
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/NSFormatter.h>
#import <Foundation/NSException.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSNumberFormatter.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSString.h>
#include <math.h>
#import <Foundation/NSCoder.h>
#import "NSObjectInternal.h"

#ifndef NSFormattingUnitStyleShort
enum {
    NSFormattingUnitStyleShort = 1,
    NSFormattingUnitStyleMedium,
    NSFormattingUnitStyleLong,
};
#endif

@implementation NSFormatter

- (NSString *)stringForObjectValue:(id)obj
{
    NSRequestConcreteImplementation();
    return nil;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs
{
    return nil;
}

- (NSString *)editingStringForObjectValue:(id)obj
{
    return [self stringForObjectValue:obj];
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error
{
    NSRequestConcreteImplementation();
    return NO;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString
            errorDescription:(NSString **)error
{
    return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
              originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error
{
    NSString *editingString = nil;
    BOOL success = [self isPartialStringValid:*partialStringPtr newEditingString:&editingString errorDescription:error];
    if (success)
    {
        return YES;
    }

    if (editingString != nil && proposedSelRangePtr != NULL)
    {
        proposedSelRangePtr->location = [editingString length];
        proposedSelRangePtr->length = 0;
    }

    return success;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    return;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

@end


// Shared helpers for the unit formatters below.
static NSNumberFormatter *_NSUnitFormatterNumberFormatter(NSNumberFormatter *custom)
{
    if (custom != nil)
    {
        return custom;
    }
    NSNumberFormatter *nf = [[[NSNumberFormatter alloc] init] autorelease];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    [nf setMaximumFractionDigits:3];
    return nf;
}

static BOOL _NSUnitFormatterUsesMetric(void)
{
    NSNumber *metric = [[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem];
    return metric == nil ? YES : [metric boolValue];
}

static NSString *_NSUnitFormatterJoin(NSString *number, NSString *shortUnit, NSString *longUnit, NSInteger style)
{
    switch (style)
    {
        case 1: // NSFormattingUnitStyleShort
            return [NSString stringWithFormat:@"%@%@", number, shortUnit];
        case 3: // NSFormattingUnitStyleLong
            return [NSString stringWithFormat:@"%@ %@", number, longUnit];
        default:
            return [NSString stringWithFormat:@"%@ %@", number, shortUnit];
    }
}

@interface NSDateIntervalFormatter : NSFormatter {
    NSLocale *_locale;
    NSCalendar *_calendar;
    NSTimeZone *_timeZone;
    NSUInteger _dateStyle;
    NSUInteger _timeStyle;
}
- (NSCalendar *)calendar;
- (void)setCalendar:(NSCalendar *)calendar;
- (NSUInteger)dateStyle;
- (void)setDateStyle:(NSUInteger)dateStyle;
- (NSLocale *)locale;
- (void)setLocale:(NSLocale *)locale;
- (NSUInteger)timeStyle;
- (void)setTimeStyle:(NSUInteger)timeStyle;
- (NSTimeZone *)timeZone;
- (void)setTimeZone:(NSTimeZone *)timeZone;
- (NSString *)stringFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;
@end

@implementation NSDateIntervalFormatter

- (void)dealloc
{
    [_locale release];
    [_calendar release];
    [_timeZone release];
    [super dealloc];
}

- (NSLocale *)locale
{
    return _locale != nil ? _locale : [NSLocale currentLocale];
}

- (void)setLocale:(NSLocale *)locale
{
    if (_locale != locale)
    {
        [_locale release];
        _locale = [locale copy];
    }
}

- (NSCalendar *)calendar
{
    if (_calendar != nil)
    {
        return _calendar;
    }
    NSCalendar *cal = [[self locale] objectForKey:NSLocaleCalendar];
    return cal != nil ? cal : [NSCalendar currentCalendar];
}

- (void)setCalendar:(NSCalendar *)calendar
{
    if (_calendar != calendar)
    {
        [_calendar release];
        _calendar = [calendar copy];
    }
}

- (NSTimeZone *)timeZone
{
    return _timeZone != nil ? _timeZone : [NSTimeZone defaultTimeZone];
}

- (void)setTimeZone:(NSTimeZone *)timeZone
{
    if (_timeZone != timeZone)
    {
        [_timeZone release];
        _timeZone = [timeZone copy];
    }
}

- (NSUInteger)dateStyle
{
    return _dateStyle;
}

- (void)setDateStyle:(NSUInteger)dateStyle
{
    _dateStyle = dateStyle;
}

- (NSUInteger)timeStyle
{
    return _timeStyle;
}

- (void)setTimeStyle:(NSUInteger)timeStyle
{
    _timeStyle = timeStyle;
}

- (NSString *)stringFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSDateFormatter *full = [[[NSDateFormatter alloc] init] autorelease];
    [full setLocale:[self locale]];
    [full setCalendar:[self calendar]];
    [full setTimeZone:[self timeZone]];
    [full setDateStyle:(NSDateFormatterStyle)_dateStyle];
    [full setTimeStyle:(NSDateFormatterStyle)_timeStyle];

    NSString *start = [full stringFromDate:fromDate];
    NSString *end = [full stringFromDate:toDate];
    if ([start isEqualToString:end])
    {
        return start;
    }

    // Same day with a time component: print the date once and then the time range.
    if (_dateStyle != 0 && _timeStyle != 0)
    {
        NSCalendar *cal = [self calendar];
        NSTimeZone *oldZone = [[[cal timeZone] retain] autorelease];
        [cal setTimeZone:[self timeZone]];
        NSUInteger dayUnits = NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
        NSDateComponents *c1 = [cal components:dayUnits fromDate:fromDate];
        NSDateComponents *c2 = [cal components:dayUnits fromDate:toDate];
        BOOL sameDay = [c1 era] == [c2 era] && [c1 year] == [c2 year] && [c1 month] == [c2 month] && [c1 day] == [c2 day];
        [cal setTimeZone:oldZone];
        if (sameDay)
        {
            NSDateFormatter *dateOnly = [[[NSDateFormatter alloc] init] autorelease];
            [dateOnly setLocale:[self locale]];
            [dateOnly setCalendar:[self calendar]];
            [dateOnly setTimeZone:[self timeZone]];
            [dateOnly setDateStyle:(NSDateFormatterStyle)_dateStyle];
            [dateOnly setTimeStyle:NSDateFormatterNoStyle];
            NSDateFormatter *timeOnly = [[[NSDateFormatter alloc] init] autorelease];
            [timeOnly setLocale:[self locale]];
            [timeOnly setCalendar:[self calendar]];
            [timeOnly setTimeZone:[self timeZone]];
            [timeOnly setDateStyle:NSDateFormatterNoStyle];
            [timeOnly setTimeStyle:(NSDateFormatterStyle)_timeStyle];
            return [NSString stringWithFormat:@"%@, %@ – %@", [dateOnly stringFromDate:fromDate],
                    [timeOnly stringFromDate:fromDate], [timeOnly stringFromDate:toDate]];
        }
    }
    return [NSString stringWithFormat:@"%@ – %@", start, end];
}

- (NSString *)stringForObjectValue:(id)obj
{
    return nil;
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error
{
    return NO;
}

@end

@interface NSEnergyFormatter : NSFormatter {
    NSNumberFormatter *_numberFormatter;
    NSInteger _unitStyle;
    BOOL _isForFoodEnergyUse;
}
- (BOOL)isForFoodEnergyUse;
- (void)setForFoodEnergyUse:(BOOL)forFoodEnergyUse;
- (NSInteger)unitStyle;
- (void)setUnitStyle:(NSInteger)unitStyle;
- (NSString *)stringFromJoules:(double)numberInJoules;
@end

@implementation NSEnergyFormatter

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _unitStyle = NSFormattingUnitStyleMedium;
    }
    return self;
}

- (void)dealloc
{
    [_numberFormatter release];
    [super dealloc];
}

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    self = [self init];
    return self;
}

- (BOOL)isForFoodEnergyUse
{
    return _isForFoodEnergyUse;
}

- (void)setForFoodEnergyUse:(BOOL)forFoodEnergyUse
{
    _isForFoodEnergyUse = forFoodEnergyUse;
}

- (NSInteger)unitStyle
{
    return _unitStyle;
}

- (void)setUnitStyle:(NSInteger)unitStyle
{
    _unitStyle = unitStyle;
}

- (NSNumberFormatter *)numberFormatter
{
    if (_numberFormatter == nil)
    {
        _numberFormatter = [_NSUnitFormatterNumberFormatter(nil) retain];
    }
    return _numberFormatter;
}

- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter
{
    if (_numberFormatter != numberFormatter)
    {
        [_numberFormatter release];
        _numberFormatter = [numberFormatter retain];
    }
}

- (NSString *)stringFromJoules:(double)numberInJoules
{
    double value = numberInJoules;
    NSString *shortUnit;
    NSString *longUnit;
    if (_NSUnitFormatterUsesMetric())
    {
        if (fabs(value) >= 1000.0)
        {
            value /= 1000.0;
            shortUnit = @"kJ";
            longUnit = @"kilojoules";
        }
        else
        {
            shortUnit = @"J";
            longUnit = @"joules";
        }
    }
    else
    {
        value /= 4.184; // calories
        if (_isForFoodEnergyUse)
        {
            value /= 1000.0;
            shortUnit = @"C";
            longUnit = @"Calories";
        }
        else if (fabs(value) >= 1000.0)
        {
            value /= 1000.0;
            shortUnit = @"kcal";
            longUnit = @"kilocalories";
        }
        else
        {
            shortUnit = @"cal";
            longUnit = @"calories";
        }
    }
    NSString *number = [[self numberFormatter] stringFromNumber:[NSNumber numberWithDouble:value]];
    return _NSUnitFormatterJoin(number, shortUnit, longUnit, _unitStyle);
}

- (NSString *)stringForObjectValue:(id)obj
{
    if (![obj isKindOfClass:[NSNumber class]])
    {
        return nil;
    }
    return [self stringFromJoules:[obj doubleValue]];
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error
{
    return NO;
}

@end

@interface NSLengthFormatter : NSFormatter {
    NSNumberFormatter *_numberFormatter;
    NSInteger _unitStyle;
    BOOL _isForPersonHeight;
}
- (BOOL)isForPersonHeightUse;
- (void)setForPersonHeightUse:(BOOL)forPersonHeightUse;
- (NSInteger)unitStyle;
- (void)setUnitStyle:(NSInteger)unitStyle;
- (NSString *)stringFromMeters:(double)numberInMeters;
@end

@implementation NSLengthFormatter

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _unitStyle = NSFormattingUnitStyleMedium;
    }
    return self;
}

- (void)dealloc
{
    [_numberFormatter release];
    [super dealloc];
}

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    self = [self init];
    return self;
}

- (BOOL)isForPersonHeightUse
{
    return _isForPersonHeight;
}

- (void)setForPersonHeightUse:(BOOL)forPersonHeightUse
{
    _isForPersonHeight = forPersonHeightUse;
}

- (NSInteger)unitStyle
{
    return _unitStyle;
}

- (void)setUnitStyle:(NSInteger)unitStyle
{
    _unitStyle = unitStyle;
}

- (NSNumberFormatter *)numberFormatter
{
    if (_numberFormatter == nil)
    {
        _numberFormatter = [_NSUnitFormatterNumberFormatter(nil) retain];
    }
    return _numberFormatter;
}

- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter
{
    if (_numberFormatter != numberFormatter)
    {
        [_numberFormatter release];
        _numberFormatter = [numberFormatter retain];
    }
}

- (NSString *)stringFromMeters:(double)numberInMeters
{
    double value = numberInMeters;
    NSString *shortUnit;
    NSString *longUnit;
    double a = fabs(value);
    if (_NSUnitFormatterUsesMetric())
    {
        if (_isForPersonHeight)
        {
            value *= 100.0;
            shortUnit = @"cm";
            longUnit = @"centimeters";
        }
        else if (a >= 1000.0)
        {
            value /= 1000.0;
            shortUnit = @"km";
            longUnit = @"kilometers";
        }
        else if (a >= 1.0 || a == 0.0)
        {
            shortUnit = @"m";
            longUnit = @"meters";
        }
        else if (a >= 0.01)
        {
            value *= 100.0;
            shortUnit = @"cm";
            longUnit = @"centimeters";
        }
        else
        {
            value *= 1000.0;
            shortUnit = @"mm";
            longUnit = @"millimeters";
        }
    }
    else
    {
        double feet = value / 0.3048;
        double af = fabs(feet);
        if (_isForPersonHeight)
        {
            value = feet;
            shortUnit = @"ft";
            longUnit = @"feet";
        }
        else if (af >= 5280.0)
        {
            value = feet / 5280.0;
            shortUnit = @"mi";
            longUnit = @"miles";
        }
        else if (af >= 3.0)
        {
            value = feet / 3.0;
            if (af >= 3.0 && af < 10.0)
            {
                value = feet;
                shortUnit = @"ft";
                longUnit = @"feet";
            }
            else
            {
                shortUnit = @"yd";
                longUnit = @"yards";
            }
        }
        else if (af >= 1.0)
        {
            value = feet;
            shortUnit = @"ft";
            longUnit = @"feet";
        }
        else
        {
            value = feet * 12.0;
            shortUnit = @"in";
            longUnit = @"inches";
        }
    }
    NSString *number = [[self numberFormatter] stringFromNumber:[NSNumber numberWithDouble:value]];
    return _NSUnitFormatterJoin(number, shortUnit, longUnit, _unitStyle);
}

- (NSString *)stringForObjectValue:(id)obj
{
    if (![obj isKindOfClass:[NSNumber class]])
    {
        return nil;
    }
    return [self stringFromMeters:[obj doubleValue]];
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error
{
    return NO;
}

@end

@interface NSMassFormatter : NSFormatter {
    NSNumberFormatter *_numberFormatter;
    NSInteger _unitStyle;
    BOOL _isForPersonMassUse;
}
- (BOOL)isForPersonMassUse;
- (void)setForPersonMassUse:(BOOL)forPersonMassUse;
- (NSInteger)unitStyle;
- (void)setUnitStyle:(NSInteger)unitStyle;
- (NSString *)stringFromKilograms:(double)numberInKilograms;
@end

@implementation NSMassFormatter

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _unitStyle = NSFormattingUnitStyleMedium;
    }
    return self;
}

- (void)dealloc
{
    [_numberFormatter release];
    [super dealloc];
}

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    self = [self init];
    return self;
}

- (BOOL)isForPersonMassUse
{
    return _isForPersonMassUse;
}

- (void)setForPersonMassUse:(BOOL)forPersonMassUse
{
    _isForPersonMassUse = forPersonMassUse;
}

- (NSInteger)unitStyle
{
    return _unitStyle;
}

- (void)setUnitStyle:(NSInteger)unitStyle
{
    _unitStyle = unitStyle;
}

- (NSNumberFormatter *)numberFormatter
{
    if (_numberFormatter == nil)
    {
        _numberFormatter = [_NSUnitFormatterNumberFormatter(nil) retain];
    }
    return _numberFormatter;
}

- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter
{
    if (_numberFormatter != numberFormatter)
    {
        [_numberFormatter release];
        _numberFormatter = [numberFormatter retain];
    }
}

- (NSString *)stringFromKilograms:(double)numberInKilograms
{
    double value = numberInKilograms;
    NSString *shortUnit;
    NSString *longUnit;
    double a = fabs(value);
    if (_NSUnitFormatterUsesMetric())
    {
        if (_isForPersonMassUse || a >= 1.0 || a == 0.0)
        {
            shortUnit = @"kg";
            longUnit = @"kilograms";
        }
        else
        {
            value *= 1000.0;
            shortUnit = @"g";
            longUnit = @"grams";
        }
    }
    else
    {
        double pounds = value / 0.45359237;
        if (_isForPersonMassUse || fabs(pounds) >= 1.0 || pounds == 0.0)
        {
            value = pounds;
            shortUnit = @"lb";
            longUnit = @"pounds";
        }
        else
        {
            value = pounds * 16.0;
            shortUnit = @"oz";
            longUnit = @"ounces";
        }
    }
    NSString *number = [[self numberFormatter] stringFromNumber:[NSNumber numberWithDouble:value]];
    return _NSUnitFormatterJoin(number, shortUnit, longUnit, _unitStyle);
}

- (NSString *)stringForObjectValue:(id)obj
{
    if (![obj isKindOfClass:[NSNumber class]])
    {
        return nil;
    }
    return [self stringFromKilograms:[obj doubleValue]];
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error
{
    return NO;
}

@end
