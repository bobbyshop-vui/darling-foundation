#import <Foundation/NSCalendar.h>

@interface NSDateComponents (XcodeAdditions)

- (BOOL)isLeapMonth;
- (void)setLeapMonth:(BOOL)leapMonth;
- (BOOL)isValidDate;
- (BOOL)isValidDateInCalendar:(NSCalendar *)calendar;
- (void)setValue:(NSInteger)value forComponent:(NSCalendarUnit)unit;
- (NSInteger)valueForComponent:(NSCalendarUnit)unit;

@end
