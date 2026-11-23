#import <Foundation/NSFileProviderService.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/FoundationErrors.h>
#import <dispatch/dispatch.h>

@implementation NSFileProviderService

- (instancetype)initWithName:(NSFileProviderServiceName)name
{
    if ((self = [super init])) {
        _name = [name copy];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithName:@""];
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (NSFileProviderServiceName)name
{
    return [[_name copy] autorelease];
}

- (void)getFileProviderConnectionWithCompletionHandler:(void (^)(NSXPCConnection *connection, NSError *error))completionHandler
{
    void (^handler)(NSXPCConnection *, NSError *) = [completionHandler copy];
    /* There are no file provider extensions to connect to. */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFeatureUnsupportedError userInfo:nil];
        if (handler != nil) {
            handler(nil, error);
        }
        [handler release];
    });
}

@end
