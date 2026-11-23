#import <Foundation/NSMessagePortNameServer.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSPort.h>
#import <Foundation/NSString.h>
#import <dispatch/dispatch.h>

/* Local-only name server: ports are registered and looked up by name within this process. */
static NSMutableDictionary *_ports; // shared by all instances
static NSLock *_lock;

@implementation NSMessagePortNameServer

+ (id)sharedInstance
{
    static NSMessagePortNameServer *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[NSMessagePortNameServer alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if ((self = [super init])) {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            _ports = [[NSMutableDictionary alloc] init];
            _lock = [[NSLock alloc] init];
        });
    }
    return self;
}

- (NSPort *)portForName:(NSString *)name
{
    if (name == nil) {
        return nil;
    }
    [_lock lock];
    NSPort *port = [[[_ports objectForKey:name] retain] autorelease];
    [_lock unlock];
    return port;
}

- (NSPort *)portForName:(NSString *)name host:(NSString *)host
{
    /* A local-only server: the host must be nil or empty. */
    if (host != nil && [host length] > 0) {
        return nil;
    }
    return [self portForName:name];
}

- (BOOL)registerPort:(NSPort *)port name:(NSString *)name
{
    if (port == nil || name == nil) {
        return NO;
    }
    BOOL registered = NO;
    [_lock lock];
    if ([_ports objectForKey:name] == nil) {
        [_ports setObject:port forKey:name];
        registered = YES;
    }
    [_lock unlock];
    return registered;
}

- (BOOL)removePortForName:(NSString *)name
{
    /* Cancelling a registration is not supported by this name server. */
    return NO;
}

@end
