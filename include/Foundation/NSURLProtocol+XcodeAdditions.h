#import <Foundation/NSURLProtocol.h>

@class NSURLSessionTask;

/* -task (macOS 10.10 SDK). The task is only known for protocol instances that
   were created for a session task, so it is nil otherwise. */
@interface NSURLProtocol (XcodeAdditions)

- (NSURLSessionTask *)task;

@end
