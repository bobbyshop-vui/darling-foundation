#import <Foundation/NSUserUnixTask.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSString.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSURL.h>
#import <Foundation/FoundationErrors.h>
#import <dispatch/dispatch.h>

@implementation NSUserUnixTask

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
        _unixScriptURL = [url copy];
    }
    return self;
}

- (void)dealloc
{
    [_unixScriptURL release];
    [_unixStandardInput release];
    [_unixStandardOutput release];
    [_unixStandardError release];
    [super dealloc];
}

- (NSURL *)scriptURL
{
    return [[_unixScriptURL copy] autorelease];
}

- (NSFileHandle *)standardInput
{
    return _unixStandardInput;
}

- (void)setStandardInput:(NSFileHandle *)handle
{
    if (_unixStandardInput != handle) {
        [_unixStandardInput release];
        _unixStandardInput = [handle retain];
    }
}

- (NSFileHandle *)standardOutput
{
    return _unixStandardOutput;
}

- (void)setStandardOutput:(NSFileHandle *)handle
{
    if (_unixStandardOutput != handle) {
        [_unixStandardOutput release];
        _unixStandardOutput = [handle retain];
    }
}

- (NSFileHandle *)standardError
{
    return _unixStandardError;
}

- (void)setStandardError:(NSFileHandle *)handle
{
    if (_unixStandardError != handle) {
        [_unixStandardError release];
        _unixStandardError = [handle retain];
    }
}

- (void)executeWithCompletionHandler:(void (^)(NSError *error))handler
{
    [self executeWithArguments:nil completionHandler:handler];
}

- (void)executeWithArguments:(NSArray<NSString *> *)arguments completionHandler:(NSUserUnixTaskCompletionHandler)handler
{
    /* A script task can be executed only once. */
    if (_unixExecuted) {
        [NSException raise:NSInvalidArgumentException format:@"An NSUserScriptTask can only be executed once"];
    }
    _unixExecuted = YES;

    NSURL *url = [[_unixScriptURL copy] autorelease];
    NSArray *args = [[arguments copy] autorelease];
    NSFileHandle *input = [[_unixStandardInput retain] autorelease];
    NSFileHandle *output = [[_unixStandardOutput retain] autorelease];
    NSFileHandle *errput = [[_unixStandardError retain] autorelease];
    NSUserUnixTaskCompletionHandler completion = [[handler copy] autorelease];

    [url retain]; [args retain]; [input retain]; [output retain]; [errput retain]; [completion retain];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *failure = nil;
        NSTask *task = [[NSTask alloc] init];
        [task setExecutableURL:url];
        if (args != nil) {
            [task setArguments:args];
        }
        if (input != nil) {
            [task setStandardInput:input];
        }
        if (output != nil) {
            [task setStandardOutput:output];
        }
        if (errput != nil) {
            [task setStandardError:errput];
        }

        if ([task launchAndReturnError:&failure]) {
            [task waitUntilExit];
            if ([task terminationReason] != NSTaskTerminationReasonExit || [task terminationStatus] != 0) {
                failure = [NSError errorWithDomain:NSPOSIXErrorDomain
                                              code:[task terminationStatus]
                                          userInfo:nil];
            }
        }
        [task release];

        if (completion != nil) {
            completion(failure);
        }
        [url release]; [args release]; [input release]; [output release]; [errput release]; [completion release];
    });
}

@end
