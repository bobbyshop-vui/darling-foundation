#import <Foundation/NSDate+XcodeAdditions.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSString.h>
#import <Foundation/NSTimeZone.h>

/* Converts a strftime-style NSCalendarDate format ("%Y-%m-%d %H:%M:%S %z")
   into the equivalent Unicode date format pattern. Literal text is quoted. */
static NSString *XCICUPatternForCalendarFormat(NSString *format)
{
    NSMutableString *pattern = [NSMutableString string];
    NSUInteger length = [format length];
    NSUInteger i = 0;
    BOOL inLiteral = NO;

    for (i = 0; i < length; i++)
    {
        unichar c = [format characterAtIndex:i];
        NSString *token = nil;

        if (c == '%' && i + 1 < length)
        {
            unichar spec = [format characterAtIndex:i + 1];
            // skip the optional "1" ... "9" width digits NSCalendarDate allows
            while (spec >= '1' && spec <= '9' && i + 2 < length)
            {
                i++;
                spec = [format characterAtIndex:i + 1];
            }
            i++;
            switch (spec)
            {
                case 'Y': token = @"yyyy"; break;
                case 'y': token = @"yy"; break;
                case 'm': token = @"MM"; break;
                case 'd': token = @"dd"; break;
                case 'e': token = @"d"; break;
                case 'H': token = @"HH"; break;
                case 'I': token = @"hh"; break;
                case 'M': token = @"mm"; break;
                case 'S': token = @"ss"; break;
                case 'F': token = @"SSS"; break;
                case 'p': token = @"a"; break;
                case 'b': case 'h': token = @"MMM"; break;
                case 'B': token = @"MMMM"; break;
                case 'a': token = @"EEE"; break;
                case 'A': token = @"EEEE"; break;
                case 'j': token = @"DDD"; break;
                case 'w': token = @"e"; break;
                case 'z': token = @"Z"; break;
                case 'Z': token = @"zzz"; break;
                case 'c': token = @"EEE MMM d HH:mm:ss yyyy"; break;
                case 'x': token = @"MM/dd/yy"; break;
                case 'X': token = @"HH:mm:ss"; break;
                case '%': token = @"'%'"; break;
                default: break;
            }
            if (token != nil)
            {
                if (inLiteral)
                {
                    [pattern appendString:@"'"];
                    inLiteral = NO;
                }
                [pattern appendString:token];
                continue;
            }
            // unknown specifier: emit it literally
            c = spec;
        }

        if (c == '\'')
        {
            // a doubled quote is a literal quote both inside and outside quoted text
            [pattern appendString:@"''"];
            continue;
        }

        BOOL isLetter = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
        if (isLetter && !inLiteral)
        {
            [pattern appendString:@"'"];
            inLiteral = YES;
        }
        else if (!isLetter && inLiteral)
        {
            [pattern appendString:@"'"];
            inLiteral = NO;
        }
        [pattern appendFormat:@"%C", c];
    }
    if (inLiteral)
    {
        [pattern appendString:@"'"];
    }
    return pattern;
}

static NSLocale *XCPOSIXLocale(void)
{
    return [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
}

static NSDate *XCParseDate(NSString *string, NSString *pattern, NSTimeZone *timeZone, NSLocale *locale)
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:locale];
    [formatter setTimeZone:timeZone];
    [formatter setDateFormat:pattern];
    NSDate *date = [formatter dateFromString:string];
    [formatter release];
    return date;
}

@implementation NSDate (XcodeAdditions)

+ (id)dateWithString:(NSString *)aString
{
    return [[[self alloc] initWithString:aString] autorelease];
}

- (id)initWithString:(NSString *)description
{
    NSDate *parsed = nil;
    if (description != nil)
    {
        // "YYYY-MM-DD HH:MM:SS ±HHMM"
        parsed = XCParseDate([description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
                             @"yyyy-MM-dd HH:mm:ss Z", [NSTimeZone localTimeZone], XCPOSIXLocale());
    }
    if (parsed == nil)
    {
        [self release];
        return nil;
    }
    return [self initWithTimeIntervalSinceReferenceDate:[parsed timeIntervalSinceReferenceDate]];
}

- (NSString *)descriptionWithCalendarFormat:(NSString *)format timeZone:(NSTimeZone *)aTimeZone locale:(id)locale
{
    if (format == nil)
    {
        format = @"%Y-%m-%d %H:%M:%S %z";
    }
    if (aTimeZone == nil)
    {
        aTimeZone = [NSTimeZone localTimeZone];
    }

    NSLocale *resolved = nil;
    if ([locale isKindOfClass:[NSLocale class]])
    {
        resolved = locale;
    }
    else if ([locale isKindOfClass:[NSDictionary class]])
    {
        // legacy locale dictionaries carry the identifier, if any
        NSString *identifier = [(NSDictionary *)locale objectForKey:NSLocaleIdentifier];
        resolved = (identifier != nil) ? [NSLocale localeWithLocaleIdentifier:identifier] : XCPOSIXLocale();
    }
    else
    {
        resolved = XCPOSIXLocale();
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:resolved];
    [formatter setTimeZone:aTimeZone];
    [formatter setDateFormat:XCICUPatternForCalendarFormat(format)];
    NSString *result = [formatter stringFromDate:self];
    [formatter release];
    return result;
}

+ (id)dateWithNaturalLanguageString:(NSString *)string
{
    if (string == nil)
    {
        return nil;
    }

    NSString *text = [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    if ([text length] == 0)
    {
        return nil;
    }

    NSTimeInterval day = 24.0 * 60.0 * 60.0;
    if ([text isEqualToString:@"now"])
    {
        return [NSDate date];
    }
    if ([text isEqualToString:@"today"] || [text isEqualToString:@"tomorrow"] || [text isEqualToString:@"yesterday"])
    {
        NSDate *now = [NSDate date];
        if ([text isEqualToString:@"tomorrow"])
        {
            return [now dateByAddingTimeInterval:day];
        }
        if ([text isEqualToString:@"yesterday"])
        {
            return [now dateByAddingTimeInterval:-day];
        }
        return now;
    }

    static NSString *patterns[] = {
        @"yyyy-MM-dd HH:mm:ss Z", @"yyyy-MM-dd HH:mm:ss", @"yyyy-MM-dd'T'HH:mm:ssZ", @"yyyy-MM-dd'T'HH:mm:ss",
        @"yyyy-MM-dd HH:mm", @"yyyy-MM-dd", @"yyyy/MM/dd", @"MM/dd/yyyy HH:mm:ss", @"MM/dd/yyyy HH:mm",
        @"MM/dd/yyyy", @"MM/dd/yy", @"MMM d, yyyy h:mm a", @"MMM d, yyyy HH:mm", @"MMM d, yyyy",
        @"MMMM d, yyyy h:mm a", @"MMMM d, yyyy HH:mm", @"MMMM d, yyyy", @"d MMM yyyy HH:mm", @"d MMM yyyy",
        @"d MMMM yyyy", @"EEE, d MMM yyyy HH:mm:ss Z", @"EEE MMM d HH:mm:ss yyyy", @"h:mm a", @"HH:mm:ss", @"HH:mm",
        nil
    };

    NSLocale *locale = XCPOSIXLocale();
    NSTimeZone *zone = [NSTimeZone localTimeZone];
    NSUInteger i;
    for (i = 0; patterns[i] != nil; i++)
    {
        NSDate *date = XCParseDate(string, patterns[i], zone, locale);
        if (date != nil)
        {
            // time-only patterns parse to 1 Jan 2000; move them onto today
            if ([patterns[i] rangeOfString:@"d"].location == NSNotFound && [patterns[i] rangeOfString:@"M"].location == NSNotFound
                && [patterns[i] rangeOfString:@"y"].location == NSNotFound)
            {
                NSDate *now = [NSDate date];
                NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
                [dayFormatter setLocale:locale];
                [dayFormatter setTimeZone:zone];
                [dayFormatter setDateFormat:@"yyyy-MM-dd"];
                NSString *today = [dayFormatter stringFromDate:now];
                [dayFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
                [timeFormatter setLocale:locale];
                [timeFormatter setTimeZone:zone];
                [timeFormatter setDateFormat:@"HH:mm:ss"];
                NSString *time = [timeFormatter stringFromDate:date];
                NSDate *combined = [dayFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", today, time]];
                [dayFormatter release];
                [timeFormatter release];
                if (combined != nil)
                {
                    date = combined;
                }
            }
            return date;
        }
    }

    // finally try the localized date/time styles
    NSDateFormatterStyle styles[] = { NSDateFormatterFullStyle, NSDateFormatterLongStyle, NSDateFormatterMediumStyle, NSDateFormatterShortStyle };
    NSLocale *current = [NSLocale currentLocale];
    for (i = 0; i < 4; i++)
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:current];
        [formatter setTimeZone:zone];
        [formatter setDateStyle:styles[i]];
        NSDate *date = [formatter dateFromString:string];
        [formatter release];
        if (date != nil)
        {
            return date;
        }
    }
    return nil;
}

@end
