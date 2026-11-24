#import <Foundation/NSURLSessionTask+XcodeAdditions.h>
#import <Foundation/NSError.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSProgress.h>
#import <objc/runtime.h>

static const void *XCPriorityKey = &XCPriorityKey;
static const void *XCProgressKey = &XCProgressKey;

static const float XCDefaultPriority = 0.5f;

// NSURLSessionTask declares readonly properties which are auto-synthesized
// into ivars of the same class; keep the exposed state in sync through them.
static void *XCTaskIvar(id task, const char *name)
{
    Ivar ivar = class_getInstanceVariable(object_getClass(task), name);
    return ivar ? (void *)((char *)task + ivar_getOffset(ivar)) : NULL;
}

static NSURLSessionTaskState XCGetState(NSURLSessionTask *task)
{
    NSURLSessionTaskState *state = (NSURLSessionTaskState *)XCTaskIvar(task, "_state");
    return state ? *state : [task state];
}

static void XCSetState(NSURLSessionTask *task, NSURLSessionTaskState value)
{
    NSURLSessionTaskState *state = (NSURLSessionTaskState *)XCTaskIvar(task, "_state");
    if (state) {
        *state = value;
    }
}

@implementation NSURLSessionTask (XcodeAdditions)

- (void)resume
{
    if (XCGetState(self) == NSURLSessionTaskStateSuspended) {
        XCSetState(self, NSURLSessionTaskStateRunning);
        if ([self respondsToSelector:@selector(_startLoading)]) {
            [self performSelector:@selector(_startLoading)];
        }
    }
}

- (void)suspend
{
    if (XCGetState(self) == NSURLSessionTaskStateRunning) {
        XCSetState(self, NSURLSessionTaskStateSuspended);
    }
}

- (void)cancel
{
    NSURLSessionTaskState current = XCGetState(self);
    if (current == NSURLSessionTaskStateCanceling || current == NSURLSessionTaskStateCompleted) {
        return;
    }

    // No transport is attached to the task, so the cancellation completes
    // immediately with NSURLErrorCancelled.
    id *error = (id *)XCTaskIvar(self, "_error");
    if (error && *error == nil) {
        *error = [[NSError alloc] initWithDomain:@"NSURLErrorDomain" code:-999 userInfo:nil];
    }
    XCSetState(self, NSURLSessionTaskStateCompleted);

    NSProgress *progress = objc_getAssociatedObject(self, XCProgressKey);
    [progress cancel];
}

- (float)priority
{
    NSNumber *value = objc_getAssociatedObject(self, XCPriorityKey);
    return value ? [value floatValue] : XCDefaultPriority;
}

- (void)setPriority:(float)priority
{
    if (priority < 0.0f) {
        priority = 0.0f;
    } else if (priority > 1.0f) {
        priority = 1.0f;
    }
    objc_setAssociatedObject(self, XCPriorityKey, [NSNumber numberWithFloat:priority], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSProgress *)progress
{
    @synchronized (self) {
        NSProgress *progress = objc_getAssociatedObject(self, XCProgressKey);
        if (progress == nil) {
            progress = [NSProgress progressWithTotalUnitCount:-1];
            objc_setAssociatedObject(self, XCProgressKey, progress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        int64_t expected = [self countOfBytesExpectedToReceive];
        if (expected > 0) {
            [progress setTotalUnitCount:expected];
        }
        int64_t received = [self countOfBytesReceived];
        if (received >= 0) {
            [progress setCompletedUnitCount:received];
        }
        return progress;
    }
}

@end
