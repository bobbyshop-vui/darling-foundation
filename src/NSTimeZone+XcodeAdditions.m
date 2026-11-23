#import <Foundation/NSTimeZone+XcodeAdditions.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCharacterSet.h>
#import <dispatch/dispatch.h>

@implementation NSTimeZone (XcodeAdditions)

+ (NSString *)timeZoneDataVersion
{
    // macOS ships the tz database version in +VERSION; Linux zoneinfo packages
    // carry it on the first line of tzdata.zi ("# version 2024a").
    static NSString *version = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSArray *paths = [NSArray arrayWithObjects:
            @"/usr/share/zoneinfo/+VERSION",
            @"/var/db/timezone/zoneinfo/+VERSION",
            @"/usr/share/zoneinfo/tzdata.zi",
            @"/usr/share/zoneinfo/zone1970.tab",
            nil];
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        for (NSString *path in paths)
        {
            NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
            if ([contents length] == 0)
            {
                continue;
            }
            NSString *line = [[contents componentsSeparatedByString:@"\n"] objectAtIndex:0];
            line = [line stringByTrimmingCharactersInSet:whitespace];
            NSRange range = [line rangeOfString:@"version "];
            if (range.location != NSNotFound)
            {
                line = [[line substringFromIndex:NSMaxRange(range)] stringByTrimmingCharactersInSet:whitespace];
            }
            else if ([line hasPrefix:@"#"])
            {
                continue;
            }
            if ([line length] > 0 && [line length] < 16)
            {
                version = [line copy];
                break;
            }
        }
        if (version == nil)
        {
            version = @"";
        }
    });
    return version;
}

@end
