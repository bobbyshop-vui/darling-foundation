#import <Foundation/NSURLSession+XcodeAdditions.h>
#import <Foundation/NSOperation.h>
#import <Foundation/NSError.h>
#import <objc/runtime.h>

// The +sessionWithConfiguration:..., +sharedSession, -dataTaskWith... and
// -downloadTaskWith... methods are already inherited from __NSCFURLSession
// (NSURLSession's superclass is switched to it at +initialize), so only
// -invalidateAndCancel, which nothing implements, is added here.

@implementation NSURLSession (XcodeAdditions)

- (void)invalidateAndCancel
{
    Ivar invalidIvar = class_getInstanceVariable(object_getClass(self), "_invalid");
    BOOL *invalid = invalidIvar ? (BOOL *)((char *)self + ivar_getOffset(invalidIvar)) : NULL;
    if (invalid != NULL) {
        if (*invalid) {
            return;
        }
        *invalid = YES;
    }

    id<NSURLSessionDelegate> delegate = [self delegate];
    if (![delegate respondsToSelector:@selector(URLSession:didBecomeInvalidWithError:)]) {
        return;
    }

    [self retain];
    void (^notify)(void) = ^{
        [delegate URLSession:self didBecomeInvalidWithError:nil];
        [self release];
    };
    NSOperationQueue *queue = [self delegateQueue];
    if (queue != nil) {
        [queue addOperationWithBlock:notify];
    } else {
        notify();
    }
}

@end
