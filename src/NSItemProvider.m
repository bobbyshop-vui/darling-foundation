#import <Foundation/NSItemProvider.h>
#import <Foundation/NSData.h>
#import <Foundation/NSProgress.h>
#import <Foundation/NSError.h>
#import <Block.h>

NSString * const NSItemProviderErrorDomain = @"NSItemProviderErrorDomain";

#if __OBJC2__

typedef NSProgress * (^NSItemProviderObjectLoadHandler)(void (^completionHandler)(id<NSItemProviderWriting> object, NSError *error));

static NSProgress *completedItemProviderProgress(void)
{
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    [progress setCompletedUnitCount:1];
    return progress;
}

@interface _NSItemProviderRepresentation : NSObject
{
@public
    NSString *typeIdentifier;
    Class writerClass;
    id data;
    NSItemProviderObjectLoadHandler loadHandler;
    NSItemProviderRepresentationVisibility visibility;
}
- (instancetype)initWithTypeIdentifier:(NSString *)typeIdentifier writerClass:(Class)writerClass data:(id)data loadHandler:(NSItemProviderObjectLoadHandler)loadHandler visibility:(NSItemProviderRepresentationVisibility)visibility;
@end

@implementation _NSItemProviderRepresentation

- (instancetype)initWithTypeIdentifier:(NSString *)identifier writerClass:(Class)aClass data:(id)representationData loadHandler:(NSItemProviderObjectLoadHandler)handler visibility:(NSItemProviderRepresentationVisibility)representationVisibility
{
    self = [super init];
    if (self != nil)
    {
        typeIdentifier = [identifier copy];
        writerClass = aClass;
        data = [representationData retain];
        loadHandler = handler ? Block_copy(handler) : NULL;
        visibility = representationVisibility;
    }
    return self;
}

- (void)dealloc
{
    [typeIdentifier release];
    [data release];
    if (loadHandler != NULL)
    {
        Block_release(loadHandler);
    }
    [super dealloc];
}

@end

@implementation NSItemProvider

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _representations = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_representations release];
    [super dealloc];
}

- (instancetype)initWithContentsOfURL:(NSURL *)fileURL
{
    if (fileURL == nil)
    {
        [self release];
        return nil;
    }

    self = [self init];
    if (self != nil)
    {
        NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
        if (fileData == nil)
        {
            [self release];
            return nil;
        }

        // LaunchServices' extension-to-UTI database is not available here.
        // Keep the file contents loadable through the generic data type.
        _NSItemProviderRepresentation *representation = [[_NSItemProviderRepresentation alloc] initWithTypeIdentifier:@"public.data" writerClass:Nil data:fileData loadHandler:nil visibility:NSItemProviderRepresentationVisibilityAll];
        [_representations addObject:representation];
        [representation release];
    }
    return self;
}

- (void)registerObjectOfClass:(Class<NSItemProviderWriting>)aClass visibility:(NSItemProviderRepresentationVisibility)representationVisibility loadHandler:(NSProgress * _Nullable (^)(void (^completionHandler)(id<NSItemProviderWriting> object, NSError *error)))handler
{
    if (aClass == Nil || handler == nil || ![aClass respondsToSelector:@selector(writableTypeIdentifiersForItemProvider)])
    {
        return;
    }

    NSArray *typeIdentifiers = [aClass writableTypeIdentifiersForItemProvider];
    for (NSString *typeIdentifier in typeIdentifiers)
    {
        if (![typeIdentifier isKindOfClass:[NSString class]])
        {
            continue;
        }
        _NSItemProviderRepresentation *representation = [[_NSItemProviderRepresentation alloc] initWithTypeIdentifier:typeIdentifier writerClass:aClass data:nil loadHandler:handler visibility:representationVisibility];
        [_representations addObject:representation];
        [representation release];
    }
}

- (BOOL)canLoadObjectOfClass:(Class<NSItemProviderReading>)aClass
{
    if (aClass == Nil || ![aClass respondsToSelector:@selector(readableTypeIdentifiersForItemProvider)])
    {
        return NO;
    }

    NSArray *readableTypes = [aClass readableTypeIdentifiersForItemProvider];
    for (_NSItemProviderRepresentation *representation in _representations)
    {
        if ([readableTypes containsObject:representation->typeIdentifier])
        {
            return YES;
        }
    }
    return NO;
}

- (NSProgress *)loadObjectOfClass:(Class<NSItemProviderReading>)aClass completionHandler:(void (^)(id<NSItemProviderReading> object, NSError *error))completionHandler
{
    NSArray *readableTypes = (aClass != Nil && [aClass respondsToSelector:@selector(readableTypeIdentifiersForItemProvider)]) ? [aClass readableTypeIdentifiersForItemProvider] : nil;
    for (_NSItemProviderRepresentation *representation in _representations)
    {
        if (![readableTypes containsObject:representation->typeIdentifier])
        {
            continue;
        }

        if (representation->data != nil)
        {
            NSError *error = nil;
            id<NSItemProviderReading> object = [aClass objectWithItemProviderData:representation->data typeIdentifier:representation->typeIdentifier error:&error];
            if (completionHandler != nil)
            {
                completionHandler(object, error);
            }
            return completedItemProviderProgress();
        }

        if (representation->loadHandler != NULL)
        {
            NSProgress *fallbackProgress = [NSProgress progressWithTotalUnitCount:1];
            NSProgress *progress = representation->loadHandler(^(id<NSItemProviderWriting> object, NSError *error) {
                if (object != nil && ![object isKindOfClass:aClass])
                {
                    error = [NSError errorWithDomain:NSItemProviderErrorDomain code:NSItemProviderUnexpectedValueClassError userInfo:nil];
                    object = nil;
                }
                if (completionHandler != nil)
                {
                    completionHandler((id<NSItemProviderReading>)object, error);
                }
                [fallbackProgress setCompletedUnitCount:1];
            });
            return progress ?: fallbackProgress;
        }
    }

    if (completionHandler != nil)
    {
        completionHandler(nil, [NSError errorWithDomain:NSItemProviderErrorDomain code:NSItemProviderItemUnavailableError userInfo:nil]);
    }
    return completedItemProviderProgress();
}

- (NSRect)containerFrame
{
    return NSZeroRect;
}

- (NSRect)sourceFrame
{
    return NSZeroRect;
}

@end

#else

@implementation NSItemProvider
@end

#endif
