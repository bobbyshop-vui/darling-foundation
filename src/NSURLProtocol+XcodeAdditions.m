#import <Foundation/NSURLProtocol+XcodeAdditions.h>
#import <Foundation/NSURLSession.h>
#import <objc/runtime.h>

static char XCURLProtocolTaskKey;

@interface NSURLProtocol (XcodeAdditionsPrivate)
- (void)_setTask:(NSURLSessionTask *)task;
@end

@implementation NSURLProtocol (XcodeAdditions)

- (NSURLSessionTask *)task
{
    return objc_getAssociatedObject(self, &XCURLProtocolTaskKey);
}

- (void)_setTask:(NSURLSessionTask *)task
{
    objc_setAssociatedObject(self, &XCURLProtocolTaskKey, task, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
