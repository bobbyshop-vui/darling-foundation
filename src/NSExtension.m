#import <Foundation/NSExtension.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <dlfcn.h>

/*
 * Discovery is delegated to PlugInKit (PKHost), which enumerates the host
 * app's Contents/PlugIns and Contents/Extensions appexes.  Foundation cannot
 * link PlugInKit, so it is looked up dynamically.
 */
static NSArray *NSExtensionDiscover(NSDictionary *attributes)
{
    Class hostClass = NSClassFromString(@"PKHost");
    if (hostClass == Nil) {
        dlopen("/System/Library/PrivateFrameworks/PlugInKit.framework/PlugInKit", RTLD_LAZY);
        hostClass = NSClassFromString(@"PKHost");
    }
    id host = [(id)hostClass performSelector: @selector(defaultHost)];
    SEL sel = @selector(discoverPlugInsForAttributes:flags:);
    if (host == nil || ![host respondsToSelector: sel]) {
        return @[];
    }
    NSArray *(*discover)(id, SEL, id, NSUInteger) = (NSArray *(*)(id, SEL, id, NSUInteger))objc_msgSend;
    return discover(host, sel, attributes, 0) ?: @[];
}

static NSArray *NSExtensionsFromPlugIns(NSArray *plugIns)
{
    NSMutableArray *extensions = [NSMutableArray arrayWithCapacity: [plugIns count]];
    for (id plugIn in plugIns) {
        NSExtension *extension = [[NSExtension alloc] _initWithPKPlugin: plugIn];
        [extensions addObject: extension];
        [extension release];
    }
    return extensions;
}

@implementation NSExtension

@synthesize _plugIn = _plugIn;

+ (NSExtension *)extensionWithIdentifier:(NSString *)identifier error:(NSError **)error
{
    for (NSExtension *extension in NSExtensionsFromPlugIns(NSExtensionDiscover(@{})))
        if ([[extension identifier] isEqualToString: identifier])
            return extension;
    if (error)
        *error = [NSError errorWithDomain: NSCocoaErrorDomain code: NSFileNoSuchFileError userInfo: nil];
    return nil;
}

+ (NSArray *)extensionsWithMatchingAttributes:(NSDictionary *)attributes error:(NSError **)error
{
    return NSExtensionsFromPlugIns(NSExtensionDiscover(attributes));
}

+ (id)beginMatchingExtensionsWithAttributes:(NSDictionary *)attributes
                                 completion:(void (^)(NSArray *, NSError *))completion
{
    id context = [[NSObject alloc] init];
    void (^handler)(NSArray *, NSError *) = [completion copy];
    NSDictionary *attrs = [attributes copy];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        if (handler)
            handler(NSExtensionsFromPlugIns(NSExtensionDiscover(attrs)), nil);
        [handler release];
        [attrs release];
    });
    return [context autorelease];
}

+ (void)endMatchingExtensions:(id)matchingContext
{
}

- (instancetype)_initWithPKPlugin:(id)plugIn
{
    if ((self = [super init])) {
        _plugIn = [plugIn retain];
        _uuid = [[NSUUID alloc] init];
        // There is no pkd keeping per-user elections; extensions that were
        // found are in use, as built-in extensions are on macOS.
        _optedIn = YES;
    }
    return self;
}

- (void)dealloc
{
    [_plugIn release];
    [_uuid release];
    [super dealloc];
}

- (BOOL)optedIn { return _optedIn; }
- (void)setOptedIn:(BOOL)optedIn { _optedIn = optedIn; }
- (void)_setOptedIn:(BOOL)optedIn { _optedIn = optedIn; }
- (NSInteger)userElection { return _optedIn ? 1 : 2; } // PKUserElectionUse / Ignore
- (void)setUserElection:(NSInteger)election { _optedIn = (election != 2); }
- (BOOL)isEnabled { return _optedIn; }
- (BOOL)_isEnabled { return _optedIn; }
- (void)_setEnabled:(BOOL)enabled { _optedIn = enabled; }

- (NSString *)extensionPointIdentifier
{
    return [[self attributes] objectForKey: @"NSExtensionPointIdentifier"];
}
- (NSString *)_extensionPointIdentifier { return [self extensionPointIdentifier]; }
- (NSUUID *)_uuid { return _uuid; }
- (NSUUID *)UUID { return _uuid; }
- (NSArray *)icons { return @[]; }
- (BOOL)_isSystemExtension { return YES; }
- (BOOL)_isMarkedNew { return NO; }
- (pid_t)_plugInProcessIdentifier { return 0; }
- (pid_t)pidForRequestIdentifier:(NSUUID *)identifier { return 0; }

- (id)objectForInfoDictionaryKey:(NSString *)key
{
    return [[self infoDictionary] objectForKey: key];
}

// Xcode calls more of the private NSExtension API than is implemented here.
// An unrecognized selector raised inside IDEExtension's locked queue, and the
// exception handler then hung while holding it, freezing Xcode; answer unknown
// messages with nil/0 and log them instead.
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [super methodSignatureForSelector: aSelector];
    return signature ? signature : [NSMethodSignature signatureWithObjCTypes: "@@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSLog(@"NSExtension: unimplemented -%@ (returning nil)", NSStringFromSelector([anInvocation selector]));
    id result = nil;
    if ([[anInvocation methodSignature] methodReturnLength] <= sizeof(result))
        [anInvocation setReturnValue: &result];
}

- (NSString *)identifier { return [_plugIn identifier]; }
- (NSDictionary *)infoDictionary { return [_plugIn infoDictionary]; }
- (NSDictionary *)attributes { return [[self infoDictionary] objectForKey: @"NSExtension"]; }
- (NSString *)version { return [_plugIn version]; }
- (NSString *)localizedName { return [_plugIn name]; }

- (NSBundle *)_extensionBundle
{
    NSURL *url = [(id)_plugIn performSelector: @selector(url)];
    return url ? [NSBundle bundleWithURL: url] : nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"<%@: %p> %@", [self class], self, [self identifier]];
}

/*
 * Darling has no pkd / extension host process, so an extension request can
 * never be started.  Report that honestly.
 */
- (void)beginExtensionRequestWithInputItems:(NSArray *)inputItems
                                 completion:(void (^)(NSUUID *))completion
{
    if (completion)
        completion(nil);
}

- (void)setRequestInterruptionBlock:(void (^)(NSUUID *))block {}
- (void)setRequestCancellationBlock:(void (^)(NSUUID *, NSError *))block {}
- (NSExtensionContext *)_extensionContextForUUID:(NSUUID *)uuid { return nil; }
- (void)cancelExtensionRequestWithIdentifier:(NSUUID *)uuid {}

@end
