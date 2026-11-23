#import <Foundation/NSCalendar.h>

@class NSArray, NSDate, NSDateComponents, NSLocale, NSTimeZone, NSString;

/* Methods the macOS 10.14 SDK declares for NSCalendar that the bridged
   __NSCFCalendar / NSAutoCalendar classes do not provide. They are written
   against the public primitives of NSCalendar so every concrete subclass
   inherits them. NSCalendarOptions values are passed as NSUInteger, like the
   rest of the Darling NSCalendar interface. */
@interface NSCalendar (XcodeAdditions)

+ (NSCalendar *)calendarWithIdentifier:(NSCalendarIdentifier)calendarIdentifierConstant;

- (NSArray *)eraSymbols;
- (NSArray *)longEraSymbols;
- (NSArray *)monthSymbols;
- (NSArray *)shortMonthSymbols;
- (NSArray *)veryShortMonthSymbols;
- (NSArray *)standaloneMonthSymbols;
- (NSArray *)shortStandaloneMonthSymbols;
- (NSArray *)veryShortStandaloneMonthSymbols;
- (NSArray *)weekdaySymbols;
- (NSArray *)shortWeekdaySymbols;
- (NSArray *)veryShortWeekdaySymbols;
- (NSArray *)standaloneWeekdaySymbols;
- (NSArray *)shortStandaloneWeekdaySymbols;
- (NSArray *)veryShortStandaloneWeekdaySymbols;
- (NSArray *)quarterSymbols;
- (NSArray *)shortQuarterSymbols;
- (NSArray *)standaloneQuarterSymbols;
- (NSArray *)shortStandaloneQuarterSymbols;
- (NSString *)AMSymbol;
- (NSString *)PMSymbol;

- (NSInteger)component:(NSCalendarUnit)unit fromDate:(NSDate *)date;
- (NSDate *)startOfDayForDate:(NSDate *)date;
- (NSDateComponents *)componentsInTimeZone:(NSTimeZone *)timezone fromDate:(NSDate *)date;
- (NSComparisonResult)compareDate:(NSDate *)date1 toDate:(NSDate *)date2 toUnitGranularity:(NSCalendarUnit)unit;
- (BOOL)isDate:(NSDate *)date1 equalToDate:(NSDate *)date2 toUnitGranularity:(NSCalendarUnit)unit;
- (BOOL)isDate:(NSDate *)date1 inSameDayAsDate:(NSDate *)date2;
- (BOOL)isDateInToday:(NSDate *)date;
- (BOOL)isDateInYesterday:(NSDate *)date;
- (BOOL)isDateInTomorrow:(NSDate *)date;
- (BOOL)isDateInWeekend:(NSDate *)date;
- (BOOL)rangeOfWeekendStartDate:(NSDate **)datep interval:(NSTimeInterval *)tip containingDate:(NSDate *)date;
- (BOOL)nextWeekendStartDate:(NSDate **)datep interval:(NSTimeInterval *)tip options:(NSUInteger)options afterDate:(NSDate *)date;
- (NSDateComponents *)components:(NSCalendarUnit)unitFlags fromDateComponents:(NSDateComponents *)startingDateComp toDateComponents:(NSDateComponents *)resultDateComp options:(NSUInteger)options;
- (NSDate *)dateByAddingUnit:(NSCalendarUnit)unit value:(NSInteger)value toDate:(NSDate *)date options:(NSUInteger)options;
- (void)enumerateDatesStartingAfterDate:(NSDate *)start matchingComponents:(NSDateComponents *)comps options:(NSUInteger)opts usingBlock:(void (^)(NSDate *date, BOOL exactMatch, BOOL *stop))block;
- (NSDate *)nextDateAfterDate:(NSDate *)date matchingComponents:(NSDateComponents *)comps options:(NSUInteger)options;
- (NSDate *)dateBySettingUnit:(NSCalendarUnit)unit value:(NSInteger)v ofDate:(NSDate *)date options:(NSUInteger)opts;
- (NSDate *)dateBySettingHour:(NSInteger)h minute:(NSInteger)m second:(NSInteger)s ofDate:(NSDate *)date options:(NSUInteger)opts;
- (BOOL)date:(NSDate *)date matchesComponents:(NSDateComponents *)components;

@end
