#import <Foundation/NSRunLoop.h>

/* -performBlock: (macOS 10.12 SDK). */
@interface NSRunLoop (XcodeAdditions)

- (void)performBlock:(void (^)(void))block;

@end
