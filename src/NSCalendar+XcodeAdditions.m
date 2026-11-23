#import <Foundation/NSCalendar+XcodeAdditions.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSTimeZone.h>
#import <limits.h>
#import <math.h>

@interface NSDateComponents (XcodeAdditionsPrivate)
- (NSInteger)nanosecond;
- (void)setNanosecond:(NSInteger)nsec;
@end

enum {
    XCWrapComponents = 1 << 0,
    XCMatchStrictly = 1 << 1,
    XCSearchBackwards = 1 << 2,
};

static const NSCalendarUnit XCAllUnits =
    NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
    NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitNanosecond |
    NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal | NSCalendarUnitQuarter |
    NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekOfYear | NSCalendarUnitYearForWeekOfYear;

static BOOL XCIsUndefined(NSInteger v)
{
    return v >= INT_MAX || v == NSUndefinedDateComponent;
}

static NSInteger XCValueForUnit(NSDateComponents *c, NSCalendarUnit unit)
{
    switch (unit) {
        case NSCalendarUnitEra: return [c era];
        case NSCalendarUnitYear: return [c year];
        case NSCalendarUnitMonth: return [c month];
        case NSCalendarUnitDay: return [c day];
        case NSCalendarUnitHour: return [c hour];
        case NSCalendarUnitMinute: return [c minute];
        case NSCalendarUnitSecond: return [c second];
        case NSCalendarUnitNanosecond: return [c nanosecond];
        case NSCalendarUnitWeekday: return [c weekday];
        case NSCalendarUnitWeekdayOrdinal: return [c weekdayOrdinal];
        case NSCalendarUnitQuarter: return [c quarter];
        case NSCalendarUnitWeekOfMonth: return [c weekOfMonth];
        case NSCalendarUnitWeekOfYear: return [c weekOfYear];
        case NSCalendarUnitYearForWeekOfYear: return [c yearForWeekOfYear];
        default: return NSUndefinedDateComponent;
    }
}

static void XCSetValueForUnit(NSDateComponents *c, NSCalendarUnit unit, NSInteger v)
{
    switch (unit) {
        case NSCalendarUnitEra: [c setEra:v]; break;
        case NSCalendarUnitYear: [c setYear:v]; break;
        case NSCalendarUnitMonth: [c setMonth:v]; break;
        case NSCalendarUnitDay: [c setDay:v]; break;
        case NSCalendarUnitHour: [c setHour:v]; break;
        case NSCalendarUnitMinute: [c setMinute:v]; break;
        case NSCalendarUnitSecond: [c setSecond:v]; break;
        case NSCalendarUnitNanosecond: [c setNanosecond:v]; break;
        case NSCalendarUnitWeekday: [c setWeekday:v]; break;
        case NSCalendarUnitWeekdayOrdinal: [c setWeekdayOrdinal:v]; break;
        case NSCalendarUnitQuarter: [c setQuarter:v]; break;
        case NSCalendarUnitWeekOfMonth: [c setWeekOfMonth:v]; break;
        case NSCalendarUnitWeekOfYear: [c setWeekOfYear:v]; break;
        case NSCalendarUnitYearForWeekOfYear: [c setYearForWeekOfYear:v]; break;
        default: break;
    }
}

/* Units of a components object that have a value set. */
static NSCalendarUnit XCSpecifiedUnits(NSDateComponents *c)
{
    NSCalendarUnit result = 0;
    for (NSUInteger bit = 0; bit < 16; bit++) {
        NSCalendarUnit unit = (NSCalendarUnit)1 << bit;
        if ((XCAllUnits & unit) && !XCIsUndefined(XCValueForUnit(c, unit))) {
            result |= unit;
        }
    }
    return result;
}

/* Maps a unit to the unit used to measure/skip its time range. */
static NSCalendarUnit XCRangeUnit(NSCalendarUnit unit)
{
    switch (unit) {
        case NSCalendarUnitWeekday:
        case NSCalendarUnitWeekdayOrdinal:
        case NSCalendarUnitWeekOfMonth:
        case NSCalendarUnitWeekOfYear:
            return NSCalendarUnitDay;
        case NSCalendarUnitYearForWeekOfYear:
            return NSCalendarUnitYear;
        default:
            return unit;
    }
}

@implementation NSCalendar (XcodeAdditions)

+ (NSCalendar *)calendarWithIdentifier:(NSCalendarIdentifier)calendarIdentifierConstant
{
    if (calendarIdentifierConstant == nil) {
        return nil;
    }
    return [[[NSCalendar alloc] initWithCalendarIdentifier:calendarIdentifierConstant] autorelease];
}

#pragma mark - Symbols

- (NSDateFormatter *)_xcSymbolFormatter
{
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    NSLocale *locale = [self locale];
    if (locale != nil) {
        [formatter setLocale:locale];
    }
    [formatter setTimeZone:[self timeZone]];
    [formatter setCalendar:self];
    return formatter;
}

- (NSArray *)eraSymbols { return [[self _xcSymbolFormatter] eraSymbols]; }
- (NSArray *)longEraSymbols { return [[self _xcSymbolFormatter] longEraSymbols]; }
- (NSArray *)monthSymbols { return [[self _xcSymbolFormatter] monthSymbols]; }
- (NSArray *)shortMonthSymbols { return [[self _xcSymbolFormatter] shortMonthSymbols]; }
- (NSArray *)veryShortMonthSymbols { return [[self _xcSymbolFormatter] veryShortMonthSymbols]; }
- (NSArray *)standaloneMonthSymbols { return [[self _xcSymbolFormatter] standaloneMonthSymbols]; }
- (NSArray *)shortStandaloneMonthSymbols { return [[self _xcSymbolFormatter] shortStandaloneMonthSymbols]; }
- (NSArray *)veryShortStandaloneMonthSymbols { return [[self _xcSymbolFormatter] veryShortStandaloneMonthSymbols]; }
- (NSArray *)weekdaySymbols { return [[self _xcSymbolFormatter] weekdaySymbols]; }
- (NSArray *)shortWeekdaySymbols { return [[self _xcSymbolFormatter] shortWeekdaySymbols]; }
- (NSArray *)veryShortWeekdaySymbols { return [[self _xcSymbolFormatter] veryShortWeekdaySymbols]; }
- (NSArray *)standaloneWeekdaySymbols { return [[self _xcSymbolFormatter] standaloneWeekdaySymbols]; }
- (NSArray *)shortStandaloneWeekdaySymbols { return [[self _xcSymbolFormatter] shortStandaloneWeekdaySymbols]; }
- (NSArray *)veryShortStandaloneWeekdaySymbols { return [[self _xcSymbolFormatter] veryShortStandaloneWeekdaySymbols]; }
- (NSArray *)quarterSymbols { return [[self _xcSymbolFormatter] quarterSymbols]; }
- (NSArray *)shortQuarterSymbols { return [[self _xcSymbolFormatter] shortQuarterSymbols]; }
- (NSArray *)standaloneQuarterSymbols { return [[self _xcSymbolFormatter] standaloneQuarterSymbols]; }
- (NSArray *)shortStandaloneQuarterSymbols { return [[self _xcSymbolFormatter] shortStandaloneQuarterSymbols]; }
- (NSString *)AMSymbol { return [[self _xcSymbolFormatter] AMSymbol]; }
- (NSString *)PMSymbol { return [[self _xcSymbolFormatter] PMSymbol]; }

#pragma mark - Components

- (NSInteger)component:(NSCalendarUnit)unit fromDate:(NSDate *)date
{
    NSDateComponents *c = [self components:unit fromDate:date];
    if (c == nil) {
        return NSUndefinedDateComponent;
    }
    return XCValueForUnit(c, unit);
}

- (NSDate *)startOfDayForDate:(NSDate *)date
{
    NSDate *start = nil;
    NSTimeInterval interval = 0;
    if ([self rangeOfUnit:NSCalendarUnitDay startDate:&start interval:&interval forDate:date]) {
        return start;
    }
    return date;
}

- (NSDateComponents *)componentsInTimeZone:(NSTimeZone *)timezone fromDate:(NSDate *)date
{
    NSCalendar *zoned = [[self copy] autorelease];
    [zoned setTimeZone:timezone];
    NSDateComponents *c = [zoned components:(XCAllUnits & ~NSCalendarUnitNanosecond) fromDate:date];
    NSTimeInterval t = [date timeIntervalSinceReferenceDate];
    [c setNanosecond:(NSInteger)llround((t - floor(t)) * 1000000000.0) % 1000000000];
    [c setCalendar:self];
    [c setTimeZone:timezone];
    return c;
}

- (NSDateComponents *)components:(NSCalendarUnit)unitFlags fromDateComponents:(NSDateComponents *)startingDateComp toDateComponents:(NSDateComponents *)resultDateComp options:(NSUInteger)options
{
    if (startingDateComp == nil || resultDateComp == nil) {
        return nil;
    }
    NSCalendar *startCal = [startingDateComp calendar] ?: self;
    NSCalendar *endCal = [resultDateComp calendar] ?: self;
    NSDate *start = [startCal dateFromComponents:startingDateComp];
    NSDate *end = [endCal dateFromComponents:resultDateComp];
    if (start == nil || end == nil) {
        return nil;
    }
    return [self components:unitFlags fromDate:start toDate:end options:options];
}

- (NSDate *)dateByAddingUnit:(NSCalendarUnit)unit value:(NSInteger)value toDate:(NSDate *)date options:(NSUInteger)options
{
    NSDateComponents *c = [[[NSDateComponents alloc] init] autorelease];
    XCSetValueForUnit(c, unit, value);
    return [self dateByAddingComponents:c toDate:date options:options];
}

#pragma mark - Comparison

- (NSComparisonResult)compareDate:(NSDate *)date1 toDate:(NSDate *)date2 toUnitGranularity:(NSCalendarUnit)unit
{
    NSTimeInterval t1 = [date1 timeIntervalSinceReferenceDate];
    NSTimeInterval t2 = [date2 timeIntervalSinceReferenceDate];
    if (unit != NSCalendarUnitNanosecond) {
        NSDate *s1 = nil, *s2 = nil;
        NSTimeInterval i1 = 0, i2 = 0;
        NSCalendarUnit rangeUnit = XCRangeUnit(unit);
        if ([self rangeOfUnit:rangeUnit startDate:&s1 interval:&i1 forDate:date1] &&
            [self rangeOfUnit:rangeUnit startDate:&s2 interval:&i2 forDate:date2]) {
            t1 = [s1 timeIntervalSinceReferenceDate];
            t2 = [s2 timeIntervalSinceReferenceDate];
        }
    }
    if (t1 < t2) return NSOrderedAscending;
    if (t1 > t2) return NSOrderedDescending;
    return NSOrderedSame;
}

- (BOOL)isDate:(NSDate *)date1 equalToDate:(NSDate *)date2 toUnitGranularity:(NSCalendarUnit)unit
{
    return [self compareDate:date1 toDate:date2 toUnitGranularity:unit] == NSOrderedSame;
}

- (BOOL)isDate:(NSDate *)date1 inSameDayAsDate:(NSDate *)date2
{
    return [self isDate:date1 equalToDate:date2 toUnitGranularity:NSCalendarUnitDay];
}

- (BOOL)isDateInToday:(NSDate *)date
{
    return [self isDate:date inSameDayAsDate:[NSDate date]];
}

- (BOOL)isDateInYesterday:(NSDate *)date
{
    NSDate *yesterday = [self dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:[NSDate date] options:0];
    return yesterday != nil && [self isDate:date inSameDayAsDate:yesterday];
}

- (BOOL)isDateInTomorrow:(NSDate *)date
{
    NSDate *tomorrow = [self dateByAddingUnit:NSCalendarUnitDay value:1 toDate:[NSDate date] options:0];
    return tomorrow != nil && [self isDate:date inSameDayAsDate:tomorrow];
}

#pragma mark - Weekends (Saturday and Sunday)

- (BOOL)isDateInWeekend:(NSDate *)date
{
    NSInteger weekday = [self component:NSCalendarUnitWeekday fromDate:date];
    return weekday == 1 || weekday == 7;
}

- (BOOL)rangeOfWeekendStartDate:(NSDate **)datep interval:(NSTimeInterval *)tip containingDate:(NSDate *)date
{
    NSInteger weekday = [self component:NSCalendarUnitWeekday fromDate:date];
    if (weekday != 1 && weekday != 7) {
        return NO;
    }
    NSDate *start = [self startOfDayForDate:date];
    if (weekday == 1) {
        start = [self startOfDayForDate:[self dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:start options:0]];
    }
    NSDate *end = [self dateByAddingUnit:NSCalendarUnitDay value:2 toDate:start options:0];
    if (start == nil || end == nil) {
        return NO;
    }
    if (datep) *datep = start;
    if (tip) *tip = [end timeIntervalSinceDate:start];
    return YES;
}

- (BOOL)nextWeekendStartDate:(NSDate **)datep interval:(NSTimeInterval *)tip options:(NSUInteger)options afterDate:(NSDate *)date
{
    NSInteger weekday = [self component:NSCalendarUnitWeekday fromDate:date];
    NSDate *day = [self startOfDayForDate:date];
    BOOL backwards = (options & XCSearchBackwards) != 0;
    NSInteger offset;
    if (backwards) {
        offset = -(weekday % 7);
    } else {
        offset = (7 - weekday) % 7;
    }
    NSDate *start = [self dateByAddingUnit:NSCalendarUnitDay value:offset toDate:day options:0];
    if (start == nil) {
        return NO;
    }
    if (backwards) {
        if ([start timeIntervalSinceDate:date] >= 0) {
            start = [self dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:start options:0];
        }
    } else if ([start timeIntervalSinceDate:date] <= 0) {
        start = [self dateByAddingUnit:NSCalendarUnitDay value:7 toDate:start options:0];
    }
    NSDate *end = [self dateByAddingUnit:NSCalendarUnitDay value:2 toDate:start options:0];
    if (start == nil || end == nil) {
        return NO;
    }
    if (datep) *datep = start;
    if (tip) *tip = [end timeIntervalSinceDate:start];
    return YES;
}

#pragma mark - Matching

- (BOOL)_xcDate:(NSDate *)date matchesComponents:(NSDateComponents *)comps units:(NSCalendarUnit)units
{
    NSDateComponents *actual = [self components:units fromDate:date];
    if (actual == nil) {
        return NO;
    }
    for (NSUInteger bit = 0; bit < 16; bit++) {
        NSCalendarUnit unit = (NSCalendarUnit)1 << bit;
        if ((units & unit) == 0) {
            continue;
        }
        if (XCValueForUnit(actual, unit) != XCValueForUnit(comps, unit)) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)date:(NSDate *)date matchesComponents:(NSDateComponents *)components
{
    if (date == nil || components == nil) {
        return NO;
    }
    NSCalendar *cal = self;
    if ([components timeZone] != nil && ![[components timeZone] isEqual:[self timeZone]]) {
        cal = [[self copy] autorelease];
        [cal setTimeZone:[components timeZone]];
    }
    NSCalendarUnit units = XCSpecifiedUnits(components);
    return [cal _xcDate:date matchesComponents:components units:units];
}

- (NSDate *)nextDateAfterDate:(NSDate *)date matchingComponents:(NSDateComponents *)comps options:(NSUInteger)options
{
    if (date == nil || comps == nil) {
        return nil;
    }
    NSCalendar *cal = self;
    if ([comps timeZone] != nil && ![[comps timeZone] isEqual:[self timeZone]]) {
        cal = [[self copy] autorelease];
        [cal setTimeZone:[comps timeZone]];
    }
    NSCalendarUnit units = XCSpecifiedUnits(comps);
    // Sub-second matching is not supported by the search.
    units &= ~NSCalendarUnitNanosecond;
    if (units == 0) {
        return nil;
    }

    // Ordered from the largest to the smallest unit.
    static const NSCalendarUnit order[] = {
        NSCalendarUnitEra, NSCalendarUnitYear, NSCalendarUnitYearForWeekOfYear, NSCalendarUnitQuarter,
        NSCalendarUnitMonth, NSCalendarUnitWeekOfYear, NSCalendarUnitWeekOfMonth, NSCalendarUnitDay,
        NSCalendarUnitWeekday, NSCalendarUnitWeekdayOrdinal, NSCalendarUnitHour, NSCalendarUnitMinute,
        NSCalendarUnitSecond
    };
    const NSUInteger orderCount = sizeof(order) / sizeof(order[0]);

    NSCalendarUnit smallest = 0;
    for (NSUInteger i = orderCount; i > 0; i--) {
        if (units & order[i - 1]) {
            smallest = XCRangeUnit(order[i - 1]);
            break;
        }
    }

    BOOL backwards = (options & XCSearchBackwards) != 0;
    NSDate *start = nil;
    NSTimeInterval interval = 0;

    // First candidate: the boundary of the smallest unit strictly after (before) the date.
    NSDate *probe = backwards ? [date dateByAddingTimeInterval:-0.001] : date;
    if (![cal rangeOfUnit:smallest startDate:&start interval:&interval forDate:probe]) {
        return nil;
    }
    NSDate *candidate = backwards ? start : [start dateByAddingTimeInterval:interval];

    for (NSUInteger iteration = 0; iteration < 100000; iteration++) {
        NSDateComponents *actual = [cal components:units fromDate:candidate];
        if (actual == nil) {
            return nil;
        }
        NSCalendarUnit mismatch = 0;
        for (NSUInteger i = 0; i < orderCount; i++) {
            if ((units & order[i]) && XCValueForUnit(actual, order[i]) != XCValueForUnit(comps, order[i])) {
                mismatch = order[i];
                break;
            }
        }
        if (mismatch == 0) {
            return candidate;
        }
        NSCalendarUnit skipUnit = XCRangeUnit(mismatch);
        if (![cal rangeOfUnit:skipUnit startDate:&start interval:&interval forDate:candidate]) {
            return nil;
        }
        if (backwards) {
            NSDate *before = [start dateByAddingTimeInterval:-0.001];
            NSDate *aligned = nil;
            NSTimeInterval alignedInterval = 0;
            if (![cal rangeOfUnit:smallest startDate:&aligned interval:&alignedInterval forDate:before]) {
                return nil;
            }
            candidate = aligned;
        } else {
            candidate = [start dateByAddingTimeInterval:interval];
        }
    }
    return nil;
}

- (void)enumerateDatesStartingAfterDate:(NSDate *)start matchingComponents:(NSDateComponents *)comps options:(NSUInteger)opts usingBlock:(void (^)(NSDate *date, BOOL exactMatch, BOOL *stop))block
{
    if (block == nil) {
        return;
    }
    NSDate *current = start;
    BOOL stop = NO;
    while (!stop) {
        NSDate *next = [self nextDateAfterDate:current matchingComponents:comps options:opts];
        if (next == nil) {
            break;
        }
        BOOL backwards = (opts & XCSearchBackwards) != 0;
        NSTimeInterval delta = [next timeIntervalSinceDate:current];
        if (backwards ? delta >= 0 : delta <= 0) {
            break;
        }
        block(next, YES, &stop);
        current = next;
    }
}

#pragma mark - Setting

- (NSDate *)dateBySettingUnit:(NSCalendarUnit)unit value:(NSInteger)v ofDate:(NSDate *)date options:(NSUInteger)opts
{
    NSInteger current = [self component:unit fromDate:date];
    if (XCIsUndefined(current)) {
        return nil;
    }
    NSDate *result = [self dateByAddingUnit:unit value:(v - current) toDate:date options:0];
    if (result != nil && (opts & XCMatchStrictly) && [self component:unit fromDate:result] != v) {
        return nil;
    }
    return result;
}

- (NSDate *)dateBySettingHour:(NSInteger)h minute:(NSInteger)m second:(NSInteger)s ofDate:(NSDate *)date options:(NSUInteger)opts
{
    NSDateComponents *c = [self components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    if (c == nil) {
        return nil;
    }
    [c setHour:h];
    [c setMinute:m];
    [c setSecond:s];
    NSDate *result = [self dateFromComponents:c];
    if (result != nil && (opts & XCMatchStrictly)) {
        NSDateComponents *check = [self components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:result];
        if ([check hour] != h || [check minute] != m || [check second] != s) {
            return nil;
        }
    }
    return result;
}

@end
