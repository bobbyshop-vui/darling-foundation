#import <Foundation/NSUserAutomatorTask.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/FoundationErrors.h>
#import <dispatch/dispatch.h>

@implementation NSUserAutomatorTask

- (instancetype)initWithURL:(NSURL *)url error:(NSError **)error
{
    if (url == nil || ![url isFileURL] ||
        ![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:nil];
        }
        [self release];
        return nil;
    }
    if ((self = [super init])) {
        _automatorScriptURL = [url copy];
    }
    return self;
}

- (void)dealloc
{
    [_automatorScriptURL release];
    [_variables release];
    [super dealloc];
}

- (NSURL *)scriptURL
{
    return [[_automatorScriptURL copy] autorelease];
}

- (NSDictionary<NSString *, id> *)variables
{
    return _variables;
}

- (void)setVariables:(NSDictionary<NSString *, id> *)variables
{
    if (_variables != variables) {
        [_variables release];
        _variables = [variables copy];
    }
}

- (void)executeWithCompletionHandler:(void (^)(NSError *error))handler
{
    void (^completion)(NSError *) = [[handler copy] autorelease];
    [self executeWithInput:nil completionHandler:^(id result, NSError *error) {
        if (completion != nil) {
            completion(error);
        }
    }];
}

- (void)executeWithInput:(id<NSSecureCoding>)input completionHandler:(NSUserAutomatorTaskCompletionHandler)handler
{
    NSUserAutomatorTaskCompletionHandler completion = [handler copy];

    /* There is no Automator runtime available; report that the workflow cannot be run. */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFeatureUnsupportedError userInfo:nil];
        if (completion != nil) {
            completion(nil, error);
        }
        [completion release];
    });
}

@end
