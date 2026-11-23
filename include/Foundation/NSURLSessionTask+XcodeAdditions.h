#import <Foundation/NSURLSession.h>

@class NSProgress;

@interface NSURLSessionTask (XcodeAdditions)

- (void)cancel;
- (void)suspend;
- (void)resume;
- (float)priority;
- (void)setPriority:(float)priority;
- (NSProgress *)progress;

@end
