#import <Foundation/NSLocale+XcodeAdditions.h>
#import <Foundation/NSString.h>
#import <CoreFoundation/CoreFoundation.h>

@implementation NSLocale (XcodeAdditions)

- (NSString *)calendarIdentifier
{
    CFTypeRef value = CFLocaleGetValue((CFLocaleRef)self, kCFLocaleCalendarIdentifier);
    if (value != NULL && CFGetTypeID(value) == CFStringGetTypeID())
    {
        return [[(NSString *)value copy] autorelease];
    }
    return @"gregorian";
}

@end
