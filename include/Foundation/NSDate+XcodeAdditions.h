#import <Foundation/NSDate.h>

@class NSString, NSTimeZone;

/* Deprecated NSCalendarDateExtras methods the macOS 10.14 SDK declares on
   NSDate. Implemented with NSDateFormatter. */
@interface NSDate (XcodeAdditions)

+ (id)dateWithNaturalLanguageString:(NSString *)string;
+ (id)dateWithString:(NSString *)aString;
- (NSString *)descriptionWithCalendarFormat:(NSString *)format timeZone:(NSTimeZone *)aTimeZone locale:(id)locale;
- (id)initWithString:(NSString *)description;

@end
