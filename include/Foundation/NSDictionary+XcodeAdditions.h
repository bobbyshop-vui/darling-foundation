#import <Foundation/NSDictionary.h>

@class NSError, NSURL;

/* NSDictionary URL/error variant the macOS 10.14 SDK declares. */
@interface NSDictionary (XcodeAdditions)

- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error;

@end
