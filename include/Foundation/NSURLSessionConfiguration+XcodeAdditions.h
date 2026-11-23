#import <Foundation/NSURLSession.h>

/* +ephemeralSessionConfiguration: declared in the Darling header but not
   implemented. */
@interface NSURLSessionConfiguration (XcodeAdditions)

+ (NSURLSessionConfiguration *)ephemeralSessionConfiguration;

@end
