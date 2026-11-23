//
//  NSDate.m
//  Foundation
//
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/NSDate.h>

#import "NSExternals.h"
#import "NSObjectInternal.h"

#import <Foundation/NSCoder.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSString.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSPortCoder.h>

@implementation NSDate (NSDate)

- (Class)classForCoder
{
    return [NSDate self];
}

OBJC_PROTOCOL_IMPL_PUSH
- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSTimeInterval timeInterval = 0.0;
    if ([aDecoder allowsKeyedCoding])
    {
        timeInterval = [aDecoder decodeDoubleForKey:NS_time];
    }
    else
    {
        [aDecoder decodeValueOfObjCType:@encode(NSTimeInterval) at:&timeInterval];
    }
    return [self initWithTimeIntervalSinceReferenceDate:timeInterval];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSTimeInterval timeInterval = [self timeIntervalSinceReferenceDate];
    if ([aCoder allowsKeyedCoding])
    {
        [aCoder encodeDouble:timeInterval forKey:NS_time];
    }
    else
    {
        [aCoder encodeValueOfObjCType:@encode(NSTimeInterval) at:&timeInterval];
    }
}
OBJC_PROTOCOL_IMPL_POP

@end


@implementation NSDate (NSDatePortCoding)

- (id) replacementObjectForPortCoder: (NSPortCoder *) portCoder {
    return self;
}

@end

@implementation NSCalendarDate

static NSString * const NSCalendarDateDefaultFormat = @"%Y-%m-%d %H:%M:%S %z";

- (id)initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ti
{
    self = [super init];
    if (self != nil)
    {
        _calDateInterval = ti;
    }
    return self;
}

- (NSTimeInterval)timeIntervalSinceReferenceDate
{
    return _calDateInterval;
}

- (void)dealloc
{
    [_calDateTimeZone release];
    [_calDateFormat release];
    [super dealloc];
}

- (NSString *)calendarFormat
{
    return _calDateFormat != nil ? _calDateFormat : NSCalendarDateDefaultFormat;
}

- (void)setCalendarFormat:(NSString *)format
{
    if (format != _calDateFormat)
    {
        [_calDateFormat release];
        _calDateFormat = [format copy];
    }
}

- (NSTimeZone *)timeZone
{
    return _calDateTimeZone != nil ? _calDateTimeZone : [NSTimeZone defaultTimeZone];
}

- (void)setTimeZone:(NSTimeZone *)aTimeZone
{
    if (aTimeZone != _calDateTimeZone)
    {
        [_calDateTimeZone release];
        _calDateTimeZone = [aTimeZone retain];
    }
}

// 0 is Sunday, 6 is Saturday.
- (NSInteger)dayOfWeek
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [calendar setTimeZone:[self timeZone]];
    NSInteger weekday = [[calendar components:NSCalendarUnitWeekday fromDate:self] weekday];
    [calendar release];
    return weekday - 1;
}

// The description has the form "YYYY-MM-DD HH:MM:SS +/-HHMM".
- (id)initWithString:(NSString *)description
{
    NSString *trimmed = [description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSDate *parsed = nil;
    NSTimeZone *zone = nil;
    if (trimmed != nil)
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        parsed = [formatter dateFromString:trimmed];
        [formatter release];

        NSRange space = [trimmed rangeOfString:@" " options:NSBackwardsSearch];
        if (parsed != nil && space.location != NSNotFound)
        {
            NSString *offset = [trimmed substringFromIndex:NSMaxRange(space)];
            if ([offset length] == 5 && ([offset hasPrefix:@"+"] || [offset hasPrefix:@"-"]))
            {
                NSInteger hours = [[offset substringWithRange:NSMakeRange(1, 2)] integerValue];
                NSInteger minutes = [[offset substringWithRange:NSMakeRange(3, 2)] integerValue];
                NSInteger seconds = hours * 3600 + minutes * 60;
                zone = [NSTimeZone timeZoneForSecondsFromGMT:[offset hasPrefix:@"-"] ? -seconds : seconds];
            }
        }
    }
    if (parsed == nil)
    {
        [self release];
        return nil;
    }
    self = [self initWithTimeIntervalSinceReferenceDate:[parsed timeIntervalSinceReferenceDate]];
    [self setTimeZone:zone];
    return self;
}

@end
