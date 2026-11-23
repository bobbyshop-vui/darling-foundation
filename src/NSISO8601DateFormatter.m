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

#import <Foundation/NSISO8601DateFormatter.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>

static const NSISO8601DateFormatOptions NSISO8601DefaultOptions =
    NSISO8601DateFormatWithInternetDateTime |
    NSISO8601DateFormatWithDashSeparatorInDate |
    NSISO8601DateFormatWithColonSeparatorInTime |
    NSISO8601DateFormatWithColonSeparatorInTimeZone;

// Darling's CoreFoundation has no CFDateFormatterCreateISO8601Formatter, so build the
// equivalent ICU pattern from the options and use a plain POSIX-locale CFDateFormatter.
static NSString *NSISO8601PatternForOptions(NSISO8601DateFormatOptions o)
{
    BOOL dash = (o & NSISO8601DateFormatWithDashSeparatorInDate) != 0;
    BOOL colon = (o & NSISO8601DateFormatWithColonSeparatorInTime) != 0;
    BOOL tzColon = (o & NSISO8601DateFormatWithColonSeparatorInTimeZone) != 0;
    NSMutableString *date = [NSMutableString string];

    if (o & NSISO8601DateFormatWithYear)
        [date appendString:@"yyyy"];
    if (o & NSISO8601DateFormatWithMonth)
        [date appendFormat:@"%@MM", [date length] && dash ? @"-" : @""];
    if (o & NSISO8601DateFormatWithWeekOfYear)
        [date appendFormat:@"%@'W'ww", [date length] && dash ? @"-" : @""];
    if (o & NSISO8601DateFormatWithDay)
    {
        NSString *day = (o & NSISO8601DateFormatWithWeekOfYear) ? @"e" :
                        (o & NSISO8601DateFormatWithMonth) ? @"dd" : @"DDD";
        [date appendFormat:@"%@%@", [date length] && dash ? @"-" : @"", day];
    }

    NSMutableString *time = [NSMutableString string];
    if (o & NSISO8601DateFormatWithTime)
    {
        [time appendString:colon ? @"HH:mm:ss" : @"HHmmss"];
        if (o & NSISO8601DateFormatWithFractionalSeconds)
            [time appendString:@".SSS"];
    }
    if (o & NSISO8601DateFormatWithTimeZone)
        [time appendString:tzColon ? @"XXX" : @"XX"];

    if ([date length] && [time length])
    {
        NSString *sep = (o & NSISO8601DateFormatWithSpaceBetweenDateAndTime) ? @" " : @"'T'";
        return [NSString stringWithFormat:@"%@%@%@", date, sep, time];
    }
    return [date length] ? date : time;
}

static CFDateFormatterRef NSISO8601CreateFormatter(NSTimeZone *timeZone, NSISO8601DateFormatOptions options)
{
    CFLocaleRef locale = CFLocaleCreate(kCFAllocatorDefault, (CFStringRef)@"en_US_POSIX");
    CFDateFormatterRef formatter = CFDateFormatterCreate(kCFAllocatorDefault, locale, kCFDateFormatterNoStyle, kCFDateFormatterNoStyle);
    if (locale != NULL)
        CFRelease(locale);
    if (formatter == NULL)
        return NULL;
    CFDateFormatterSetFormat(formatter, (CFStringRef)NSISO8601PatternForOptions(options));
    if (timeZone != nil)
        CFDateFormatterSetProperty(formatter, kCFDateFormatterTimeZone, (CFTimeZoneRef)timeZone);
    return formatter;
}

@implementation NSISO8601DateFormatter

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _timeZone = [[NSTimeZone timeZoneForSecondsFromGMT:0] retain];
        _formatOptions = NSISO8601DefaultOptions;
        _formatter = NSISO8601CreateFormatter(_timeZone, _formatOptions);
    }
    return self;
}

- (void)dealloc
{
    if (_formatter != NULL)
    {
        CFRelease(_formatter);
    }
    [_timeZone release];
    [super dealloc];
}

- (NSTimeZone *)timeZone
{
    return _timeZone;
}

- (void)setTimeZone:(NSTimeZone *)timeZone
{
    if (timeZone == nil)
    {
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    NSTimeZone *copy = [timeZone copy];
    [_timeZone release];
    _timeZone = copy;
    if (_formatter != NULL)
    {
        CFDateFormatterSetProperty(_formatter, kCFDateFormatterTimeZone, (CFTimeZoneRef)_timeZone);
    }
}

- (NSISO8601DateFormatOptions)formatOptions
{
    return _formatOptions;
}

- (void)setFormatOptions:(NSISO8601DateFormatOptions)formatOptions
{
    _formatOptions = formatOptions;
    // The format string depends on the options, so the CFDateFormatter must be regenerated.
    CFDateFormatterRef newFormatter = NSISO8601CreateFormatter(_timeZone, formatOptions);
    if (_formatter != NULL)
    {
        CFRelease(_formatter);
    }
    _formatter = newFormatter;
}

- (NSString *)stringFromDate:(NSDate *)date
{
    if (_formatter == NULL || date == nil)
    {
        return nil;
    }
    return [(NSString *)CFDateFormatterCreateStringWithDate(kCFAllocatorDefault, _formatter, (CFDateRef)date) autorelease];
}

- (NSDate *)dateFromString:(NSString *)string
{
    if (_formatter == NULL || string == nil)
    {
        return nil;
    }
    return [(NSDate *)CFDateFormatterCreateDateFromString(kCFAllocatorDefault, _formatter, (CFStringRef)string, NULL) autorelease];
}

+ (NSString *)stringFromDate:(NSDate *)date timeZone:(NSTimeZone *)timeZone formatOptions:(NSISO8601DateFormatOptions)formatOptions
{
    if (date == nil)
    {
        return nil;
    }
    CFDateFormatterRef formatter = NSISO8601CreateFormatter(timeZone, formatOptions);
    if (formatter == NULL)
    {
        return nil;
    }
    NSString *result = (NSString *)CFDateFormatterCreateStringWithDate(kCFAllocatorDefault, formatter, (CFDateRef)date);
    CFRelease(formatter);
    return [result autorelease];
}

- (NSString *)stringForObjectValue:(id)obj
{
    if ([obj isKindOfClass:[NSDate class]])
    {
        return [self stringFromDate:obj];
    }
    return nil;
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error
{
    NSDate *date = [self dateFromString:string];
    if (date == nil)
    {
        if (error != NULL)
        {
            *error = @"Unable to parse ISO 8601 date string";
        }
        return NO;
    }
    if (obj != NULL)
    {
        *obj = date;
    }
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (self && [aDecoder allowsKeyedCoding])
    {
        if ([aDecoder containsValueForKey:@"NS.timeZone"])
        {
            NSTimeZone *tz = [aDecoder decodeObjectOfClass:[NSTimeZone class] forKey:@"NS.timeZone"];
            if (tz != nil)
            {
                [self setTimeZone:tz];
            }
        }
        if ([aDecoder containsValueForKey:@"NS.formatOptions"])
        {
            [self setFormatOptions:(NSISO8601DateFormatOptions)[aDecoder decodeIntegerForKey:@"NS.formatOptions"]];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder allowsKeyedCoding])
    {
        [aCoder encodeObject:_timeZone forKey:@"NS.timeZone"];
        [aCoder encodeInteger:(NSInteger)_formatOptions forKey:@"NS.formatOptions"];
    }
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (BOOL)supportsSecureCoding
{
	return YES;
}

@end
