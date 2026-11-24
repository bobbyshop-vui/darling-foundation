#import <Foundation/NSAppleEventDescriptor.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSError.h>
#import <Foundation/NSItemProvider.h>
#import <Foundation/NSMeasurement.h>
#import <Foundation/NSPort.h>
#import <Foundation/NSRegularExpression.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSURLSession.h>
#import <Foundation/NSURLSessionTask+XcodeAdditions.h>
#import <Foundation/NSUnit.h>
#import <Foundation/NSDimension.h>
#import <Foundation/NSUnitConverter.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSHTTPCookieStorage.h>
#import <Foundation/NSURLCache.h>
#import <Foundation/NSURLCredentialStorage.h>
#import <objc/runtime.h>
#include <unistd.h>
#include <string.h>

#if !defined(__OBJC2__)
typedef void (^NSItemProviderCompletionHandler)(id item, NSError *error);
typedef void (^NSItemProviderLoadHandler)(NSItemProviderCompletionHandler completionHandler,
                                           Class expectedValueClass,
                                           NSDictionary *options);
@interface NSItemProvider : NSObject <NSCopying>
- (instancetype)init;
- (NSArray *)registeredTypeIdentifiers;
- (void)registerItemForTypeIdentifier:(NSString *)typeIdentifier
                          loadHandler:(NSItemProviderLoadHandler)loadHandler;
@end
#endif

/* These public 10.14 members are not all declared by Darling's older headers. */
@interface NSDimension (XcodeCopyPublicState)
- (NSUnitConverter *)converter;
@end

@interface NSMeasurement (XcodeCopyPublicState)
- (NSUnit *)unit;
- (double)doubleValue;
- (instancetype)initWithDoubleValue:(double)value unit:(NSUnit *)unit;
@end

@interface NSURLSessionConfiguration (XcodeCopyPublicState)
+ (NSURLSessionConfiguration *)backgroundSessionConfigurationWithIdentifier:(NSString *)identifier;
- (BOOL)waitsForConnectivity;
- (void)setWaitsForConnectivity:(BOOL)value;
- (NSString *)sharedContainerIdentifier;
- (void)setSharedContainerIdentifier:(NSString *)identifier;
- (BOOL)shouldUseExtendedBackgroundIdleMode;
- (void)setShouldUseExtendedBackgroundIdleMode:(BOOL)value;
@end

@interface NSURLSessionTask (XcodeCopyPublicState)
- (float)priority;
- (void)setPriority:(float)value;
- (NSDate *)earliestBeginDate;
- (void)setEarliestBeginDate:(NSDate *)date;
- (int64_t)countOfBytesClientExpectsToSend;
- (void)setCountOfBytesClientExpectsToSend:(int64_t)value;
- (int64_t)countOfBytesClientExpectsToReceive;
- (void)setCountOfBytesClientExpectsToReceive:(int64_t)value;
@end

@interface NSItemProvider (XcodeCopyPreviewState)
- (NSItemProviderLoadHandler)previewImageHandler;
- (void)setPreviewImageHandler:(NSItemProviderLoadHandler)handler;
@end

#define XC_AE_FOURCC(a, b, c, d) \
    (((UInt32)(a) << 24) | ((UInt32)(b) << 16) | ((UInt32)(c) << 8) | (UInt32)(d))
#define XC_AE_LIST XC_AE_FOURCC('l', 'i', 's', 't')

static Ivar XCIvar(id object, const char *name)
{
    return object == nil ? NULL : class_getInstanceVariable(object_getClass(object), name);
}

static id XCObjectIvar(id object, const char *name)
{
    Ivar ivar = XCIvar(object, name);
    return ivar == NULL ? nil : object_getIvar(object, ivar);
}

static void XCSetScalarIvar(id object, const char *name, const void *value, size_t size)
{
    Ivar ivar = XCIvar(object, name);
    if (ivar != NULL) {
        memcpy((char *)object + ivar_getOffset(ivar), value, size);
    }
}

static void XCSetObjectIvar(id object, const char *name, id value)
{
    Ivar ivar = XCIvar(object, name);
    if (ivar != NULL) {
        object_setIvar(object, ivar, value);
    }
}

static id XCCopyAppleEventDescriptor(NSAppleEventDescriptor *source, NSZone *zone)
{
    NSAppleEventDescriptor *copy = [[[source class] allocWithZone:zone]
        initWithDescriptorType:[source descriptorType] data:[source data]];
    if (copy == nil) {
        return nil;
    }

    AEEventClass eventClass = [source eventClass];
    AEEventID eventID = [source eventID];
    AEReturnID returnID = [source returnID];
    AETransactionID transactionID = [source transactionID];
    XCSetScalarIvar(copy, "_aedEventClass", &eventClass, sizeof(eventClass));
    XCSetScalarIvar(copy, "_aedEventID", &eventID, sizeof(eventID));
    XCSetScalarIvar(copy, "_aedReturnID", &returnID, sizeof(returnID));
    XCSetScalarIvar(copy, "_aedTransactionID", &transactionID, sizeof(transactionID));

    NSInteger count = [source numberOfItems];
    for (NSInteger index = 0; index < count; index++) {
        NSAppleEventDescriptor *child = [source descriptorAtIndex:index + 1];
        NSAppleEventDescriptor *childCopy = [child copyWithZone:zone];
        if ([source descriptorType] == XC_AE_LIST) {
            [copy insertDescriptor:childCopy atIndex:index + 1];
        } else {
            [copy setDescriptor:childCopy
                      forKeyword:[source keywordForDescriptorAtIndex:index + 1]];
        }
        [childCopy release];
    }

    NSMutableDictionary *sourceAttributes = XCObjectIvar(source, "_aedAttributes");
    if (sourceAttributes != nil) {
        NSMutableDictionary *copyAttributes = XCObjectIvar(copy, "_aedAttributes");
        if (copyAttributes == nil) {
            copyAttributes = [[NSMutableDictionary alloc] init];
            XCSetObjectIvar(copy, "_aedAttributes", copyAttributes);
        } else {
            [copyAttributes removeAllObjects];
        }
        for (id key in [sourceAttributes allKeys]) {
            NSAppleEventDescriptor *value = [sourceAttributes objectForKey:key];
            NSAppleEventDescriptor *valueCopy = [value copyWithZone:zone];
            if (valueCopy != nil) {
                [copyAttributes setObject:valueCopy forKey:key];
                [valueCopy release];
            }
        }
    }

    return copy;
}

@implementation NSAppleEventDescriptor (XcodeCopying)

- (id)copyWithZone:(NSZone *)zone
{
    return XCCopyAppleEventDescriptor(self, zone);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return XCCopyAppleEventDescriptor(self, zone);
}

@end

static NSCalendar *XCCopyCalendar(NSCalendar *source, NSZone *zone)
{
    NSCalendarIdentifier identifier = [source calendarIdentifier];
    if (identifier == nil) {
        return [source retain];
    }

    NSCalendar *copy = [[NSCalendar allocWithZone:zone] initWithCalendarIdentifier:identifier];
    if (copy != nil) {
        [copy setLocale:[source locale]];
        [copy setTimeZone:[source timeZone]];
        [copy setFirstWeekday:[source firstWeekday]];
        [copy setMinimumDaysInFirstWeek:[source minimumDaysInFirstWeek]];
    }
    return copy;
}

@implementation NSCalendar (XcodeCopying)

- (id)copyWithZone:(NSZone *)zone
{
    return XCCopyCalendar(self, zone);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return XCCopyCalendar(self, zone);
}

@end

static NSUnitConverter *XCConverterForDimension(NSDimension *dimension)
{
    if ([dimension respondsToSelector:@selector(converter)]) {
        return [dimension converter];
    }

    Ivar converterIvar = class_getInstanceVariable([dimension class], "_dimensionConverter");
    if (converterIvar == NULL) {
        converterIvar = class_getInstanceVariable([dimension class], "_converter");
    }
    return converterIvar == NULL ? nil : object_getIvar(dimension, converterIvar);
}

static NSUnit *XCCopyUnit(NSUnit *source, NSZone *zone)
{
    if ([source isKindOfClass:[NSDimension class]]) {
        NSDimension *dimension = (NSDimension *)source;
        Class unitClass = [source class];
        return [[unitClass allocWithZone:zone]
            initWithSymbol:[source symbol] converter:XCConverterForDimension(dimension)];
    }
    Class unitClass = [source class];
    return [[unitClass allocWithZone:zone] initWithSymbol:[source symbol]];
}

@implementation NSUnit (XcodeCopying)

- (id)copyWithZone:(NSZone *)zone
{
    return XCCopyUnit(self, zone);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return XCCopyUnit(self, zone);
}

@end

@implementation NSMeasurement (XcodeCopying)

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithDoubleValue:[self doubleValue]
                                                             unit:[self unit]];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithDoubleValue:[self doubleValue]
                                                             unit:[self unit]];
}

@end

static NSScanner *XCCopyScanner(NSScanner *source, NSZone *zone)
{
    NSScanner *copy = [[NSScanner allocWithZone:zone] initWithString:[source string]];
    if (copy != nil) {
        [copy setScanLocation:[source scanLocation]];
        [copy setCaseSensitive:[source caseSensitive]];
        [copy setCharactersToBeSkipped:[source charactersToBeSkipped]];
        [copy setLocale:[source locale]];
    }
    return copy;
}

@implementation NSScanner (XcodeCopying)

- (id)copyWithZone:(NSZone *)zone
{
    return XCCopyScanner(self, zone);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return XCCopyScanner(self, zone);
}

@end

static NSMutableArray *XCItemProviderRepresentations(NSItemProvider *provider)
{
    Ivar representationsIvar = class_getInstanceVariable([provider class], "_representations");
    return representationsIvar == NULL ? nil : object_getIvar(provider, representationsIvar);
}

static NSItemProvider *XCCopyItemProvider(NSItemProvider *source, NSZone *zone)
{
    NSItemProvider *copy = [[[source class] allocWithZone:zone] init];
    if (copy == nil) {
        return nil;
    }

    NSMutableArray *sourceRepresentations = XCItemProviderRepresentations(source);
    NSMutableArray *copyRepresentations = XCItemProviderRepresentations(copy);
    if (sourceRepresentations != nil && copyRepresentations != nil) {
        /* Registered representation records are immutable; each provider owns its array. */
        [copyRepresentations addObjectsFromArray:sourceRepresentations];
    } else {
        for (NSString *typeIdentifier in [source registeredTypeIdentifiers]) {
            [copy registerItemForTypeIdentifier:typeIdentifier
                                     loadHandler:^(NSItemProviderCompletionHandler completionHandler,
                                                   Class expectedValueClass,
                                                   NSDictionary *options) {
                (void)expectedValueClass;
                (void)options;
                if (completionHandler != nil) {
                    NSError *error = [NSError errorWithDomain:@"NSItemProviderErrorDomain"
                                                         code:-1000
                                                     userInfo:nil];
                    completionHandler(nil, error);
                }
            }];
        }
    }

    if ([source respondsToSelector:@selector(previewImageHandler)] &&
        [copy respondsToSelector:@selector(setPreviewImageHandler:)]) {
        [copy setPreviewImageHandler:[source previewImageHandler]];
    }
    return copy;
}

@implementation NSItemProvider (XcodeCopying)

- (id)copyWithZone:(NSZone *)zone
{
    return XCCopyItemProvider(self, zone);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return XCCopyItemProvider(self, zone);
}

@end

static NSURLSessionConfiguration *XCCopySessionConfiguration(NSURLSessionConfiguration *source,
                                                              NSZone *zone)
{
    NSURLSessionConfiguration *copy = nil;
    NSString *identifier = [source identifier];
    if (identifier != nil &&
        [NSURLSessionConfiguration respondsToSelector:@selector(backgroundSessionConfigurationWithIdentifier:)]) {
        copy = [[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier] retain];
    }
    if (copy == nil && identifier != nil &&
        [NSURLSessionConfiguration respondsToSelector:@selector(backgroundSessionConfiguration:)]) {
        copy = [[NSURLSessionConfiguration backgroundSessionConfiguration:identifier] retain];
    }
    if (copy == nil) {
        copy = [[NSURLSessionConfiguration allocWithZone:zone] init];
    }
    if (copy == nil) {
        return nil;
    }

    copy.requestCachePolicy = source.requestCachePolicy;
    copy.timeoutIntervalForRequest = source.timeoutIntervalForRequest;
    copy.timeoutIntervalForResource = source.timeoutIntervalForResource;
    copy.networkServiceType = source.networkServiceType;
    copy.allowsCellularAccess = source.allowsCellularAccess;
    copy.discretionary = source.discretionary;
    copy.connectionProxyDictionary = source.connectionProxyDictionary;
    copy.TLSMinimumSupportedProtocol = source.TLSMinimumSupportedProtocol;
    copy.TLSMaximumSupportedProtocol = source.TLSMaximumSupportedProtocol;
    copy.HTTPShouldUsePipelining = source.HTTPShouldUsePipelining;
    copy.HTTPShouldSetCookies = source.HTTPShouldSetCookies;
    copy.HTTPCookieAcceptPolicy = source.HTTPCookieAcceptPolicy;
    copy.HTTPAdditionalHeaders = source.HTTPAdditionalHeaders;
    copy.HTTPMaximumConnectionsPerHost = source.HTTPMaximumConnectionsPerHost;
    copy.HTTPCookieStorage = source.HTTPCookieStorage;
    copy.URLCredentialStorage = source.URLCredentialStorage;
    copy.URLCache = source.URLCache;
    copy.protocolClasses = source.protocolClasses;

    if ([source respondsToSelector:@selector(sessionSendsLaunchEvents)] &&
        [copy respondsToSelector:@selector(setSessionSendsLaunchEvents:)]) {
        copy.sessionSendsLaunchEvents = source.sessionSendsLaunchEvents;
    }
    if ([source respondsToSelector:@selector(waitsForConnectivity)] &&
        [copy respondsToSelector:@selector(setWaitsForConnectivity:)]) {
        [copy setWaitsForConnectivity:[source waitsForConnectivity]];
    }
    if ([source respondsToSelector:@selector(sharedContainerIdentifier)] &&
        [copy respondsToSelector:@selector(setSharedContainerIdentifier:)]) {
        [copy setSharedContainerIdentifier:[source sharedContainerIdentifier]];
    }
    if ([source respondsToSelector:@selector(shouldUseExtendedBackgroundIdleMode)] &&
        [copy respondsToSelector:@selector(setShouldUseExtendedBackgroundIdleMode:)]) {
        [copy setShouldUseExtendedBackgroundIdleMode:[source shouldUseExtendedBackgroundIdleMode]];
    }
    return copy;
}

@implementation NSURLSessionConfiguration (XcodeCopying)

- (id)copyWithZone:(NSZone *)zone
{
    return XCCopySessionConfiguration(self, zone);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return XCCopySessionConfiguration(self, zone);
}

@end

static NSURLSessionTask *XCCopySessionTask(NSURLSessionTask *source, NSZone *zone)
{
    (void)zone;
    NSURLRequest *request = [source currentRequest] ?: [source originalRequest];
    if (request == nil) {
        /* Stream and request-less tasks have no public constructor that can reproduce them. */
        return [source retain];
    }

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *copy = nil;
    if ([source isKindOfClass:[NSURLSessionUploadTask class]]) {
        NSData *body = [request HTTPBody];
        if (body != nil) {
            copy = [session uploadTaskWithRequest:request fromData:body];
        } else if ([request HTTPBodyStream] != nil) {
            copy = [session uploadTaskWithStreamedRequest:request];
        } else {
            /* The upload body is private to the task and is not exposed by NSURLSessionTask. */
            return [source retain];
        }
    } else if ([source isKindOfClass:[NSURLSessionDownloadTask class]]) {
        copy = [session downloadTaskWithRequest:request];
    } else if ([source isKindOfClass:[NSURLSessionDataTask class]]) {
        copy = [session dataTaskWithRequest:request];
    } else {
        return [source retain];
    }

    if (copy == nil) {
        return nil;
    }
    copy.taskDescription = [source taskDescription];
    if ([source respondsToSelector:@selector(priority)] &&
        [copy respondsToSelector:@selector(setPriority:)]) {
        copy.priority = source.priority;
    }
    if ([source respondsToSelector:@selector(earliestBeginDate)] &&
        [copy respondsToSelector:@selector(setEarliestBeginDate:)]) {
        copy.earliestBeginDate = source.earliestBeginDate;
    }
    if ([source respondsToSelector:@selector(countOfBytesClientExpectsToSend)] &&
        [copy respondsToSelector:@selector(setCountOfBytesClientExpectsToSend:)]) {
        copy.countOfBytesClientExpectsToSend = source.countOfBytesClientExpectsToSend;
    }
    if ([source respondsToSelector:@selector(countOfBytesClientExpectsToReceive)] &&
        [copy respondsToSelector:@selector(setCountOfBytesClientExpectsToReceive:)]) {
        copy.countOfBytesClientExpectsToReceive = source.countOfBytesClientExpectsToReceive;
    }
    return [copy retain];
}

@implementation NSURLSessionTask (XcodeCopying)

- (id)copyWithZone:(NSZone *)zone
{
    return XCCopySessionTask(self, zone);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return XCCopySessionTask(self, zone);
}

@end

static NSPort *XCCopyPort(NSPort *source, NSZone *zone)
{
    if ([source isKindOfClass:[NSMachPort class]]) {
        NSMachPort *machPort = (NSMachPort *)source;
        NSMachPort *copy = nil;
        if ([machPort isValid]) {
            copy = [[NSMachPort allocWithZone:zone]
                initWithMachPort:[machPort machPort] options:NSMachPortDeallocateNone];
        } else {
            copy = [[NSMachPort allocWithZone:zone] init];
            [copy invalidate];
        }
        if (copy != nil) {
            [copy setDelegate:[machPort delegate]];
        }
        return copy;
    }

    if ([source isKindOfClass:[NSSocketPort class]]) {
        NSSocketPort *socketPort = (NSSocketPort *)source;
        NSSocketNativeHandle socket = [socketPort socket];
        NSSocketPort *copy = nil;
        if (socket >= 0) {
            NSSocketNativeHandle duplicate = dup(socket);
            if (duplicate < 0) {
                return [source retain];
            }
            copy = [[NSSocketPort allocWithZone:zone]
                initWithProtocolFamily:[socketPort protocolFamily]
                             socketType:[socketPort socketType]
                               protocol:[socketPort protocol]
                                 socket:duplicate];
            if (copy == nil) {
                close(duplicate);
            }
        } else if ([socketPort address] != nil) {
            copy = [[NSSocketPort allocWithZone:zone]
                initRemoteWithProtocolFamily:[socketPort protocolFamily]
                                  socketType:[socketPort socketType]
                                    protocol:[socketPort protocol]
                                     address:[socketPort address]];
        } else {
            return [source retain];
        }
        [copy setDelegate:[socketPort delegate]];
        return copy;
    }

    /* A message port is an endpoint identity; its peer/name is not publicly readable. */
    return [source retain];
}

@implementation NSPort (XcodeCopying)

- (id)copyWithZone:(NSZone *)zone
{
    return XCCopyPort(self, zone);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return XCCopyPort(self, zone);
}

@end

@implementation NSRegularExpression (XcodeCopying)

- (id)copyWithZone:(NSZone *)zone
{
    (void)zone;
    return [self retain];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    (void)zone;
    return [self retain];
}

@end
