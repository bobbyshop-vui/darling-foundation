#import <Foundation/NSLocale.h>

/* -calendarIdentifier (macOS 10.12 SDK). */
@interface NSLocale (XcodeAdditions)

@property (readonly, copy) NSString *calendarIdentifier;

@end
