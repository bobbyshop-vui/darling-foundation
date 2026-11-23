#import <Foundation/NSDateComponents+XcodeAdditions.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSTimeZone.h>
#import <objc/runtime.h>

#ifndef NSDateComponentUndefined
#define NSDateComponentUndefined NSIntegerMax
#endif

// Implemented by NSDateComponents itself but missing from the Darling header.
@interface NSDateComponents (XcodeAdditionsPrivate)
- (NSInteger)nanosecond;
- (void)setNanosecond:(NSInteger)nanosecond;
@end

static const void *XCLeapMonthKey = &XCLeapMonthKey;

static BOOL XCComponentIsSet(NSInteger value)
{
    return value != NSDateComponentUndefined && value != INT_MAX;
}

@implementation NSDateComponents (XcodeAdditions)

- (BOOL)isLeapMonth
{
    return [objc_getAssociatedObject(self, XCLeapMonthKey) boolValue];
}

- (void)setLeapMonth:(BOOL)leapMonth
{
    objc_setAssociatedObject(self, XCLeapMonthKey, [NSNumber numberWithBool:leapMonth], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setValue:(NSInteger)value forComponent:(NSCalendarUnit)unit
{
    switch (unit) {
    case NSCalendarUnitEra: [self setEra:value]; break;
    case NSCalendarUnitYear: [self setYear:value]; break;
    case NSCalendarUnitMonth: [self setMonth:value]; break;
    case NSCalendarUnitDay: [self setDay:value]; break;
    case NSCalendarUnitHour: [self setHour:value]; break;
    case NSCalendarUnitMinute: [self setMinute:value]; break;
    case NSCalendarUnitSecond: [self setSecond:value]; break;
    case NSCalendarUnitWeekday: [self setWeekday:value]; break;
    case NSCalendarUnitWeekdayOrdinal: [self setWeekdayOrdinal:value]; break;
    case NSCalendarUnitQuarter: [self setQuarter:value]; break;
    case NSCalendarUnitWeekOfMonth: [self setWeekOfMonth:value]; break;
    case NSCalendarUnitWeekOfYear: [self setWeekOfYear:value]; break;
    case NSCalendarUnitYearForWeekOfYear: [self setYearForWeekOfYear:value]; break;
    case NSCalendarUnitNanosecond: [self setNanosecond:value]; break;
    default: break;
    }
}

- (NSInteger)valueForComponent:(NSCalendarUnit)unit
{
    switch (unit) {
    case NSCalendarUnitEra: return [self era];
    case NSCalendarUnitYear: return [self year];
    case NSCalendarUnitMonth: return [self month];
    case NSCalendarUnitDay: return [self day];
    case NSCalendarUnitHour: return [self hour];
    case NSCalendarUnitMinute: return [self minute];
    case NSCalendarUnitSecond: return [self second];
    case NSCalendarUnitWeekday: return [self weekday];
    case NSCalendarUnitWeekdayOrdinal: return [self weekdayOrdinal];
    case NSCalendarUnitQuarter: return [self quarter];
    case NSCalendarUnitWeekOfMonth: return [self weekOfMonth];
    case NSCalendarUnitWeekOfYear: return [self weekOfYear];
    case NSCalendarUnitYearForWeekOfYear: return [self yearForWeekOfYear];
    case NSCalendarUnitNanosecond: return [self nanosecond];
    default: return NSDateComponentUndefined;
    }
}

- (BOOL)isValidDate
{
    NSCalendar *calendar = [self calendar];
    if (calendar == nil) {
        return NO;
    }
    return [self isValidDateInCalendar:calendar];
}

- (BOOL)isValidDateInCalendar:(NSCalendar *)calendar
{
    if (calendar == nil) {
        return NO;
    }

    static const NSCalendarUnit units[] = {
        NSCalendarUnitEra, NSCalendarUnitYear, NSCalendarUnitMonth, NSCalendarUnitDay,
        NSCalendarUnitHour, NSCalendarUnitMinute, NSCalendarUnitSecond, NSCalendarUnitNanosecond,
        NSCalendarUnitWeekday, NSCalendarUnitWeekdayOrdinal, NSCalendarUnitQuarter,
        NSCalendarUnitWeekOfMonth, NSCalendarUnitWeekOfYear, NSCalendarUnitYearForWeekOfYear,
    };
    const size_t count = sizeof(units) / sizeof(units[0]);

    NSCalendar *workCalendar = calendar;
    NSTimeZone *zone = [self timeZone];
    if (zone != nil) {
        workCalendar = [[calendar copy] autorelease];
        [workCalendar setTimeZone:zone];
    }

    NSDate *date = [workCalendar dateFromComponents:self];
    if (date == nil) {
        return NO;
    }

    NSUInteger mask = 0;
    for (size_t i = 0; i < count; i++) {
        if (XCComponentIsSet([self valueForComponent:units[i]])) {
            mask |= units[i];
        }
    }
    if (mask == 0) {
        return YES;
    }

    NSDateComponents *roundTrip = [workCalendar components:mask fromDate:date];
    if (roundTrip == nil) {
        return NO;
    }
    for (size_t i = 0; i < count; i++) {
        NSInteger expected = [self valueForComponent:units[i]];
        if (XCComponentIsSet(expected) && [roundTrip valueForComponent:units[i]] != expected) {
            return NO;
        }
    }
    return YES;
}

@end
