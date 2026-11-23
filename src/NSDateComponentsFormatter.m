/*
 This file is part of Darling.

 Copyright (C) 2019 Lubos Dolezel

 Darling is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Darling is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Darling.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <Foundation/NSDateComponentsFormatter.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSNumberFormatter.h>
#import <Foundation/NSString.h>

#define DCF_UNIT_MASK (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)

enum { DCFUnitCount = 7 };

static const NSCalendarUnit DCFUnits[DCFUnitCount] = {
    NSCalendarUnitYear, NSCalendarUnitMonth, NSCalendarUnitWeekOfMonth, NSCalendarUnitDay,
    NSCalendarUnitHour, NSCalendarUnitMinute, NSCalendarUnitSecond
};

// Approximate length of each unit in seconds, used only for fractional values.
static const double DCFUnitSeconds[DCFUnitCount] = {
    31557600.0, 2629800.0, 604800.0, 86400.0, 3600.0, 60.0, 1.0
};

// The factor to convert one of a unit into the next smaller one, or 0 when not exact.
static const NSInteger DCFUnitFactor[DCFUnitCount] = { 0, 0, 7, 24, 60, 60, 0 };

static BOOL DCFIsUndefined(NSInteger value)
{
    return value == NSIntegerMax || value == INT32_MAX || value == NSIntegerMin;
}

static NSInteger DCFComponentValue(NSDateComponents *c, NSCalendarUnit unit)
{
    switch (unit)
    {
        case NSCalendarUnitYear: return [c year];
        case NSCalendarUnitMonth: return [c month];
        case NSCalendarUnitWeekOfMonth: return [c weekOfMonth];
        case NSCalendarUnitDay: return [c day];
        case NSCalendarUnitHour: return [c hour];
        case NSCalendarUnitMinute: return [c minute];
        case NSCalendarUnitSecond: return [c second];
        default: return NSIntegerMax;
    }
}

@implementation NSDateComponentsFormatter

+ (NSString *)localizedStringFromDateComponents:(NSDateComponents *)components unitsStyle:(NSDateComponentsFormatterUnitsStyle)unitsStyle
{
    NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
    [formatter setUnitsStyle:unitsStyle];
    NSString *result = [formatter stringFromDateComponents:components];
    [formatter release];
    return result;
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _calendar = [[NSCalendar autoupdatingCurrentCalendar] retain];
        _unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
        _zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDefault;
    }
    return self;
}

- (void)dealloc
{
    [_calendar release];
    [_referenceDate release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    NSDateComponentsFormatter *copy = [[NSDateComponentsFormatter allocWithZone:zone] init];
    [copy setCalendar:_calendar];
    [copy setReferenceDate:_referenceDate];
    copy->_allowedUnits = _allowedUnits;
    copy->_unitsStyle = _unitsStyle;
    copy->_zeroFormattingBehavior = _zeroFormattingBehavior;
    copy->_maximumUnitCount = _maximumUnitCount;
    copy->_allowsFractionalUnits = _allowsFractionalUnits;
    copy->_collapsesLargestUnit = _collapsesLargestUnit;
    copy->_includesApproximationPhrase = _includesApproximationPhrase;
    copy->_includesTimeRemainingPhrase = _includesTimeRemainingPhrase;
    return copy;
}

#pragma mark - Properties

- (NSDateComponentsFormatterUnitsStyle)unitsStyle { return _unitsStyle; }
- (void)setUnitsStyle:(NSDateComponentsFormatterUnitsStyle)unitsStyle { _unitsStyle = unitsStyle; }

- (NSCalendarUnit)allowedUnits { return _allowedUnits; }
- (void)setAllowedUnits:(NSCalendarUnit)allowedUnits
{
    if (allowedUnits & ~(NSCalendarUnit)DCF_UNIT_MASK)
    {
        [NSException raise:NSInvalidArgumentException format:@"NSDateComponentsFormatter only supports year, month, week of month, day, hour, minute and second units"];
    }
    _allowedUnits = allowedUnits;
}

- (NSDateComponentsFormatterZeroFormattingBehavior)zeroFormattingBehavior { return _zeroFormattingBehavior; }
- (void)setZeroFormattingBehavior:(NSDateComponentsFormatterZeroFormattingBehavior)zeroFormattingBehavior { _zeroFormattingBehavior = zeroFormattingBehavior; }

- (NSCalendar *)calendar { return _calendar; }
- (void)setCalendar:(NSCalendar *)calendar
{
    if (calendar != _calendar)
    {
        [_calendar release];
        _calendar = [calendar copy];
    }
}

- (NSDate *)referenceDate { return _referenceDate; }
- (void)setReferenceDate:(NSDate *)referenceDate
{
    if (referenceDate != _referenceDate)
    {
        [_referenceDate release];
        _referenceDate = [referenceDate copy];
    }
}

- (BOOL)allowsFractionalUnits { return _allowsFractionalUnits; }
- (void)setAllowsFractionalUnits:(BOOL)allowsFractionalUnits { _allowsFractionalUnits = allowsFractionalUnits; }

- (NSInteger)maximumUnitCount { return _maximumUnitCount; }
- (void)setMaximumUnitCount:(NSInteger)maximumUnitCount { _maximumUnitCount = maximumUnitCount; }

- (BOOL)collapsesLargestUnit { return _collapsesLargestUnit; }
- (void)setCollapsesLargestUnit:(BOOL)collapsesLargestUnit { _collapsesLargestUnit = collapsesLargestUnit; }

- (BOOL)includesApproximationPhrase { return _includesApproximationPhrase; }
- (void)setIncludesApproximationPhrase:(BOOL)includesApproximationPhrase { _includesApproximationPhrase = includesApproximationPhrase; }

- (BOOL)includesTimeRemainingPhrase { return _includesTimeRemainingPhrase; }
- (void)setIncludesTimeRemainingPhrase:(BOOL)includesTimeRemainingPhrase { _includesTimeRemainingPhrase = includesTimeRemainingPhrase; }

#pragma mark - Formatting entry points

- (NSCalendar *)_effectiveCalendar
{
    if (_calendar != nil)
    {
        return _calendar;
    }
    return [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
}

- (NSDate *)_effectiveReferenceDate
{
    return _referenceDate != nil ? _referenceDate : [NSDate dateWithTimeIntervalSinceReferenceDate:0];
}

- (NSString *)stringForObjectValue:(id)obj
{
    if ([obj isKindOfClass:[NSDateComponents class]])
    {
        return [self stringFromDateComponents:obj];
    }
    if ([obj isKindOfClass:[NSNumber class]])
    {
        return [self stringFromTimeInterval:[obj doubleValue]];
    }
    return nil;
}

- (NSString *)stringFromDateComponents:(NSDateComponents *)components
{
    if (components == nil)
    {
        return nil;
    }
    NSCalendarUnit allowed = _allowedUnits;
    if (allowed == 0)
    {
        for (int i = 0; i < DCFUnitCount; i++)
        {
            if (!DCFIsUndefined(DCFComponentValue(components, DCFUnits[i])))
            {
                allowed |= DCFUnits[i];
            }
        }
    }

    // Express the quantity in exactly the allowed units, counting from the reference date.
    NSCalendar *calendar = [self _effectiveCalendar];
    NSDate *start = [self _effectiveReferenceDate];
    NSDateComponents *quantity = [[components copy] autorelease];
    [quantity setCalendar:nil];
    NSDate *end = [calendar dateByAddingComponents:quantity toDate:start options:0];
    if (end == nil)
    {
        return nil;
    }
    return [self _formatFromDate:start toDate:end allowedUnits:allowed];
}

- (NSString *)stringFromDate:(NSDate *)startDate toDate:(NSDate *)endDate
{
    if (startDate == nil || endDate == nil)
    {
        return nil;
    }
    NSCalendarUnit allowed = _allowedUnits != 0 ? _allowedUnits : (NSCalendarUnit)DCF_UNIT_MASK;
    return [self _formatFromDate:startDate toDate:endDate allowedUnits:allowed];
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)ti
{
    NSDate *start = [self _effectiveReferenceDate];
    NSDate *end = [start dateByAddingTimeInterval:ti];
    return [self stringFromDate:start toDate:end];
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error
{
    // Parsing is not supported by NSDateComponentsFormatter.
    if (error != NULL)
    {
        *error = @"Parsing date components is not supported.";
    }
    return NO;
}

#pragma mark - Formatting

- (NSString *)_formatFromDate:(NSDate *)start toDate:(NSDate *)end allowedUnits:(NSCalendarUnit)allowed
{
    NSCalendar *calendar = [self _effectiveCalendar];
    BOOL negative = [end timeIntervalSinceDate:start] < 0;
    if (negative)
    {
        NSDate *swap = start;
        start = end;
        end = swap;
    }

    allowed &= DCF_UNIT_MASK;
    NSDateComponents *diff = [calendar components:allowed fromDate:start toDate:end options:0];

    // Collect the allowed units, largest first.
    double values[DCFUnitCount];
    int units[DCFUnitCount];
    int count = 0;
    for (int i = 0; i < DCFUnitCount; i++)
    {
        if (allowed & DCFUnits[i])
        {
            NSInteger v = DCFComponentValue(diff, DCFUnits[i]);
            units[count] = i;
            values[count] = DCFIsUndefined(v) ? 0 : (double)v;
            count++;
        }
    }
    if (count == 0)
    {
        return nil;
    }

    if (_allowsFractionalUnits)
    {
        NSDateComponents *whole = [[[NSDateComponents alloc] init] autorelease];
        for (int j = 0; j < count; j++)
        {
            switch (DCFUnits[units[j]])
            {
                case NSCalendarUnitYear: [whole setYear:(NSInteger)values[j]]; break;
                case NSCalendarUnitMonth: [whole setMonth:(NSInteger)values[j]]; break;
                case NSCalendarUnitWeekOfMonth: [whole setWeekOfMonth:(NSInteger)values[j]]; break;
                case NSCalendarUnitDay: [whole setDay:(NSInteger)values[j]]; break;
                case NSCalendarUnitHour: [whole setHour:(NSInteger)values[j]]; break;
                case NSCalendarUnitMinute: [whole setMinute:(NSInteger)values[j]]; break;
                case NSCalendarUnitSecond: [whole setSecond:(NSInteger)values[j]]; break;
                default: break;
            }
        }
        NSDate *covered = [calendar dateByAddingComponents:whole toDate:start options:0];
        NSTimeInterval leftover = covered != nil ? [end timeIntervalSinceDate:covered] : 0;
        if (leftover > 0)
        {
            values[count - 1] += leftover / DCFUnitSeconds[units[count - 1]];
        }
    }

    // Drop the units beyond the maximum count, starting from the first non-zero one.
    if (_maximumUnitCount > 0)
    {
        int first = 0;
        while (first < count - 1 && values[first] == 0)
        {
            first++;
        }
        for (int j = first + (int)_maximumUnitCount; j < count; j++)
        {
            values[j] = 0;
        }
        if (first + _maximumUnitCount < count)
        {
            count = first + (int)_maximumUnitCount;
        }
    }

    // Express a largest unit of one as a quantity of the next smaller unit, e.g. "1m 3s" as "63s".
    if (_collapsesLargestUnit)
    {
        int first = 0;
        while (first < count - 1 && values[first] == 0)
        {
            first++;
        }
        if (first + 1 < count && values[first] == 1 && units[first + 1] == units[first] + 1 && DCFUnitFactor[units[first + 1]] != 0)
        {
            values[first + 1] += DCFUnitFactor[units[first + 1]];
            values[first] = 0;
        }
    }

    // Zero handling.
    NSDateComponentsFormatterZeroFormattingBehavior zero = _zeroFormattingBehavior;
    BOOL dropLeading, dropMiddle, dropTrailing, pad;
    if (zero & NSDateComponentsFormatterZeroFormattingBehaviorDefault)
    {
        if (_unitsStyle == NSDateComponentsFormatterUnitsStylePositional)
        {
            dropLeading = YES;
            dropMiddle = NO;
            dropTrailing = NO;
            pad = YES;
        }
        else
        {
            dropLeading = dropMiddle = dropTrailing = YES;
            pad = NO;
        }
    }
    else
    {
        dropLeading = (zero & NSDateComponentsFormatterZeroFormattingBehaviorDropLeading) != 0;
        dropMiddle = (zero & NSDateComponentsFormatterZeroFormattingBehaviorDropMiddle) != 0;
        dropTrailing = (zero & NSDateComponentsFormatterZeroFormattingBehaviorDropTrailing) != 0;
        pad = (zero & NSDateComponentsFormatterZeroFormattingBehaviorPad) != 0;
    }

    int firstNonZero = -1, lastNonZero = -1;
    for (int j = 0; j < count; j++)
    {
        if (values[j] != 0)
        {
            if (firstNonZero < 0)
            {
                firstNonZero = j;
            }
            lastNonZero = j;
        }
    }

    double shownValues[DCFUnitCount];
    int shownUnits[DCFUnitCount];
    int shown = 0;
    for (int j = 0; j < count; j++)
    {
        BOOL isZero = (values[j] == 0);
        if (isZero)
        {
            BOOL drop;
            if (firstNonZero < 0)
            {
                // Everything is zero: keep only the smallest unit.
                drop = (j != count - 1);
            }
            else if (j < firstNonZero)
            {
                drop = dropLeading;
            }
            else if (j > lastNonZero)
            {
                drop = dropTrailing;
            }
            else
            {
                drop = dropMiddle;
            }
            if (drop)
            {
                continue;
            }
        }
        shownValues[shown] = values[j];
        shownUnits[shown] = units[j];
        shown++;
    }

    // Positional output only makes sense for hours, minutes and seconds.
    BOOL positional = (_unitsStyle == NSDateComponentsFormatterUnitsStylePositional);
    for (int j = 0; positional && j < shown; j++)
    {
        if (shownUnits[j] < 4)
        {
            positional = NO;
        }
    }

    NSString *body = [self _stringForValues:shownValues units:shownUnits count:shown positional:positional pad:pad];
    if (body == nil)
    {
        return nil;
    }
    if (negative)
    {
        body = [@"-" stringByAppendingString:body];
    }
    if (_includesApproximationPhrase)
    {
        body = [@"About " stringByAppendingString:body];
    }
    if (_includesTimeRemainingPhrase)
    {
        body = [body stringByAppendingString:@" remaining"];
    }
    return body;
}

- (NSString *)_numberString:(double)value spellOut:(BOOL)spellOut
{
    if (spellOut)
    {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterSpellOutStyle];
        NSString *spelled = [formatter stringFromNumber:@(value)];
        [formatter release];
        if ([spelled length] > 0)
        {
            return spelled;
        }
    }
    if (value == (double)(long long)value)
    {
        return [NSString stringWithFormat:@"%lld", (long long)value];
    }
    return [NSString stringWithFormat:@"%.2f", value];
}

- (NSString *)_stringForValues:(double *)values units:(int *)units count:(int)count positional:(BOOL)positional pad:(BOOL)pad
{
    if (count == 0)
    {
        return nil;
    }

    NSDateComponentsFormatterUnitsStyle style = _unitsStyle;
    if (style == NSDateComponentsFormatterUnitsStylePositional && !positional)
    {
        style = NSDateComponentsFormatterUnitsStyleAbbreviated;
    }

    if (style == NSDateComponentsFormatterUnitsStylePositional)
    {
        if (count == 1)
        {
            // A lone positional unit has no separator to distinguish it; use the abbreviated form.
            style = NSDateComponentsFormatterUnitsStyleAbbreviated;
        }
        else
        {
            NSMutableString *result = [NSMutableString string];
            for (int j = 0; j < count; j++)
            {
                NSString *number = [self _numberString:values[j] spellOut:NO];
                if (j > 0 || pad)
                {
                    if ([number length] < 2 && values[j] >= 0)
                    {
                        number = [@"0" stringByAppendingString:number];
                    }
                }
                [result appendString:j > 0 ? @":" : @""];
                [result appendString:number];
            }
            return result;
        }
    }

    static NSString * const abbreviated[DCFUnitCount] = { @"y", @"mo", @"w", @"d", @"h", @"m", @"s" };
    static NSString * const shortNames[DCFUnitCount] = { @"yr", @"mth", @"wk", @"day", @"hr", @"min", @"sec" };
    static NSString * const singular[DCFUnitCount] = { @"year", @"month", @"week", @"day", @"hour", @"minute", @"second" };
    static NSString * const plural[DCFUnitCount] = { @"years", @"months", @"weeks", @"days", @"hours", @"minutes", @"seconds" };

    NSMutableArray *parts = [NSMutableArray arrayWithCapacity:count];
    for (int j = 0; j < count; j++)
    {
        int u = units[j];
        BOOL spell = (style == NSDateComponentsFormatterUnitsStyleSpellOut);
        NSString *number = [self _numberString:values[j] spellOut:spell];
        NSString *part;
        switch (style)
        {
            case NSDateComponentsFormatterUnitsStyleAbbreviated:
                part = [number stringByAppendingString:abbreviated[u]];
                break;
            case NSDateComponentsFormatterUnitsStyleShort:
            case NSDateComponentsFormatterUnitsStyleBrief:
                part = [number stringByAppendingString:shortNames[u]];
                if (style == NSDateComponentsFormatterUnitsStyleShort && [shortNames[u] isEqualToString:@"day"] && values[j] != 1)
                {
                    part = [part stringByAppendingString:@"s"];
                }
                break;
            default:
                part = [NSString stringWithFormat:@"%@ %@", number, values[j] == 1 ? singular[u] : plural[u]];
                break;
        }
        [parts addObject:part];
    }

    NSString *separator = (style == NSDateComponentsFormatterUnitsStyleAbbreviated || style == NSDateComponentsFormatterUnitsStyleBrief) ? @" " : @", ";
    NSString *result = [parts componentsJoinedByString:separator];
    if (style == NSDateComponentsFormatterUnitsStyleSpellOut && [result length] > 0)
    {
        result = [[[result substringToIndex:1] uppercaseString] stringByAppendingString:[result substringFromIndex:1]];
    }
    return result;
}

@end
