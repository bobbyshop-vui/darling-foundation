#import <Foundation/NSBundleResourceRequest.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#import <Foundation/NSProgress.h>
#import <Foundation/NSSet.h>
#import <dispatch/dispatch.h>

/*
 * Darling has no on-demand-resources service: every resource of a bundle is on disk already.
 * A request therefore always completes successfully and immediately.
 */
@implementation NSBundleResourceRequest

- (instancetype)initWithTags:(NSSet<NSString *> *)tags
{
    return [self initWithTags:tags bundle:[NSBundle mainBundle]];
}

- (instancetype)initWithTags:(NSSet<NSString *> *)tags bundle:(NSBundle *)bundle
{
    if ((self = [super init])) {
        _tags = [tags copy];
        _bundle = [(bundle != nil ? bundle : [NSBundle mainBundle]) retain];
        _progress = [[NSProgress progressWithTotalUnitCount:1] retain];
        _loadingPriority = 0.5;
    }
    return self;
}

- (void)dealloc
{
    [_tags release];
    [_bundle release];
    [_progress release];
    [super dealloc];
}

- (double)loadingPriority
{
    return _loadingPriority;
}

- (void)setLoadingPriority:(double)priority
{
    if (priority < 0.0) priority = 0.0;
    if (priority > 1.0) priority = 1.0;
    _loadingPriority = priority;
}

- (NSSet<NSString *> *)tags
{
    return [[_tags copy] autorelease];
}

- (NSBundle *)bundle
{
    return _bundle;
}

- (NSProgress *)progress
{
    return _progress;
}

- (void)beginAccessingResourcesWithCompletionHandler:(void (^)(NSError *error))completionHandler
{
    if (_used) {
        [NSException raise:NSInternalInconsistencyException format:@"An NSBundleResourceRequest may only be used once"];
    }
    _used = YES;
    _accessing = YES;
    void (^handler)(NSError *) = [completionHandler copy];
    NSProgress *progress = [_progress retain];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [progress setCompletedUnitCount:[progress totalUnitCount]];
        if (handler != nil) {
            handler(nil);
        }
        [handler release];
        [progress release];
    });
}

- (void)conditionallyBeginAccessingResourcesWithCompletionHandler:(void (^)(BOOL resourcesAvailable))completionHandler
{
    _accessing = YES;
    void (^handler)(BOOL) = [completionHandler copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (handler != nil) {
            handler(YES);
        }
        [handler release];
    });
}

- (void)endAccessingResources
{
    _accessing = NO;
}

@end
