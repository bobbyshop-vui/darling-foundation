#import <Foundation/NSRunLoop+XcodeAdditions.h>
#import <CoreFoundation/CFRunLoop.h>

@interface NSRunLoop (XcodeAdditionsPrivate)
- (CFRunLoopRef)getCFRunLoop;
@end

@implementation NSRunLoop (XcodeAdditions)

- (void)performBlock:(void (^)(void))block
{
    if (block == nil)
    {
        return;
    }
    CFRunLoopRef runLoop = [self getCFRunLoop];
    CFRunLoopPerformBlock(runLoop, kCFRunLoopCommonModes, block);
    CFRunLoopWakeUp(runLoop);
}

@end
