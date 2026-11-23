#import <Foundation/NSArray.h>

@class NSError, NSURL;

/* NSArray URL/error variants the macOS 10.14 SDK declares. Implemented with
   NSPropertyListSerialization and NSData so every concrete subclass works. */
@interface NSArray (XcodeAdditions)

- (NSArray *)initWithContentsOfURL:(NSURL *)url error:(NSError **)error;
- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error;

@end
