#import <Foundation/NSURLRequest.h>

/* +supportsSecureCoding (macOS 10.8 SDK). */
@interface NSURLRequest (XcodeAdditions)

+ (BOOL)supportsSecureCoding;

@end
