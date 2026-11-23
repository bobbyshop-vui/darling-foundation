#import <Foundation/NSTimeZone.h>

/* +timeZoneDataVersion (macOS 10.6 SDK); declared in NSTimeZone.h but not
   implemented by the bridged classes. */
@interface NSTimeZone (XcodeAdditions)

+ (NSString *)timeZoneDataVersion;

@end
