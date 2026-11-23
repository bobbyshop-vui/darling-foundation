#import <Foundation/NSFileVersion.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSUUID.h>
#import <Foundation/FoundationErrors.h>
#import <dispatch/dispatch.h>

/*
 * Darling has no versions daemon, so versions are kept in a per-user store:
 *   ~/Library/Caches/com.apple.Darling.FileVersions/<escaped item path>/<identifier>/<item name>
 * The "current" version is the item itself and is identified by its path.
 */
@implementation NSFileVersion

static NSString *NSFileVersionStoreDirectory(NSURL *itemURL)
{
    NSString *path = [[itemURL path] stringByStandardizingPath];
    NSString *escaped = [path stringByReplacingOccurrencesOfString:@"%" withString:@"%25"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString *root = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/com.apple.Darling.FileVersions"];
    return [root stringByAppendingPathComponent:escaped];
}

static NSDate *NSFileVersionModificationDate(NSURL *url)
{
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:NULL];
    return [attrs objectForKey:NSFileModificationDate];
}

- (instancetype)initWithFileURL:(NSURL *)fileURL contentsURL:(NSURL *)contentsURL identifier:(NSString *)identifier current:(BOOL)current
{
    if ((self = [super init])) {
        _fileURL = [fileURL copy];
        _contentsURL = [contentsURL copy];
        _identifier = [identifier copy];
        _isCurrent = current;
        _localizedName = [[[fileURL path] lastPathComponent] copy];
        _modificationDate = [NSFileVersionModificationDate(contentsURL) copy];
        _isResolved = YES;
    }
    return self;
}

- (void)dealloc
{
    [_fileURL release];
    [_contentsURL release];
    [_identifier release];
    [_localizedName release];
    [_modificationDate release];
    [super dealloc];
}

+ (NSFileVersion *)versionStoredAtDirectory:(NSString *)dir identifier:(NSString *)identifier forItemAtURL:(NSURL *)url
{
    NSString *itemName = [[url path] lastPathComponent];
    NSString *versionDir = [dir stringByAppendingPathComponent:identifier];
    NSString *contents = [versionDir stringByAppendingPathComponent:itemName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:contents]) {
        return nil;
    }
    return [[[NSFileVersion alloc] initWithFileURL:url
                                       contentsURL:[NSURL fileURLWithPath:contents]
                                        identifier:identifier
                                           current:NO] autorelease];
}

+ (NSFileVersion *)currentVersionOfItemAtURL:(NSURL *)url
{
    if (url == nil || ![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        return nil;
    }
    return [[[NSFileVersion alloc] initWithFileURL:url
                                       contentsURL:url
                                        identifier:[[url path] stringByStandardizingPath]
                                           current:YES] autorelease];
}

+ (NSArray *)otherVersionsOfItemAtURL:(NSURL *)url
{
    if (url == nil || ![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        return nil;
    }
    NSString *dir = NSFileVersionStoreDirectory(url);
    NSMutableArray *versions = [NSMutableArray array];
    NSArray *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:NULL];
    for (NSString *entry in entries) {
        NSFileVersion *version = [self versionStoredAtDirectory:dir identifier:entry forItemAtURL:url];
        if (version != nil) {
            [versions addObject:version];
        }
    }
    return versions;
}

+ (NSArray *)unresolvedConflictVersionsOfItemAtURL:(NSURL *)url
{
    if (url == nil || ![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        return nil;
    }
    /* Conflict versions are only produced by iCloud, which is not available. */
    return [NSArray array];
}

+ (void)getNonlocalVersionsOfItemAtURL:(NSURL *)url completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    void (^handler)(NSArray *, NSError *) = [completionHandler copy];
    NSURL *itemURL = [url copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *result = nil;
        NSError *error = nil;
        if (itemURL != nil && [[NSFileManager defaultManager] fileExistsAtPath:[itemURL path]]) {
            /* Every stored version is local; there is nothing to download. */
            result = [NSArray array];
        } else {
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:nil];
        }
        if (handler != nil) {
            handler(result, error);
        }
        [handler release];
        [itemURL release];
    });
}

+ (NSFileVersion *)versionOfItemAtURL:(NSURL *)url forPersistentIdentifier:(id)persistentIdentifier
{
    if (url == nil || ![persistentIdentifier isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *identifier = persistentIdentifier;
    NSFileVersion *current = [self currentVersionOfItemAtURL:url];
    if (current != nil && [identifier isEqualToString:current->_identifier]) {
        return current;
    }
    if ([identifier length] == 0 || [identifier rangeOfString:@"/"].location != NSNotFound) {
        return nil;
    }
    return [self versionStoredAtDirectory:NSFileVersionStoreDirectory(url) identifier:identifier forItemAtURL:url];
}

+ (NSFileVersion *)addVersionOfItemAtURL:(NSURL *)url withContentsOfURL:(NSURL *)contentsURL options:(NSFileVersionAddingOptions)options error:(NSError **)outError
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *identifier = [[NSUUID UUID] UUIDString];
    NSString *versionDir = [NSFileVersionStoreDirectory(url) stringByAppendingPathComponent:identifier];
    NSString *destination = [versionDir stringByAppendingPathComponent:[[url path] lastPathComponent]];
    NSError *error = nil;

    if (contentsURL == nil || ![fm fileExistsAtPath:[contentsURL path]]) {
        if (outError != NULL) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:nil];
        }
        return nil;
    }
    if (![fm createDirectoryAtPath:versionDir withIntermediateDirectories:YES attributes:nil error:&error]) {
        if (outError != NULL) *outError = error;
        return nil;
    }
    BOOL ok;
    if (options & NSFileVersionAddingByMoving) {
        ok = [fm moveItemAtPath:[contentsURL path] toPath:destination error:&error];
    } else {
        ok = [fm copyItemAtPath:[contentsURL path] toPath:destination error:&error];
    }
    if (!ok) {
        [fm removeItemAtPath:versionDir error:NULL];
        if (outError != NULL) *outError = error;
        return nil;
    }
    return [[[NSFileVersion alloc] initWithFileURL:url
                                       contentsURL:[NSURL fileURLWithPath:destination]
                                        identifier:identifier
                                           current:NO] autorelease];
}

+ (NSURL *)temporaryDirectoryURLForNewVersionOfItemAtURL:(NSURL *)url
{
    NSString *dir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    return [NSURL fileURLWithPath:dir isDirectory:YES];
}

+ (BOOL)removeOtherVersionsOfItemAtURL:(NSURL *)url error:(NSError **)outError
{
    NSString *dir = NSFileVersionStoreDirectory(url);
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dir]) {
        return YES;
    }
    NSError *error = nil;
    if (![fm removeItemAtPath:dir error:&error]) {
        if (outError != NULL) *outError = error;
        return NO;
    }
    return YES;
}

- (NSURL *)URL
{
    return [[_contentsURL copy] autorelease];
}

- (NSString *)localizedName
{
    return _localizedName;
}

- (NSString *)localizedNameOfSavingComputer
{
    return nil;
}

- (NSPersonNameComponents *)originatorNameComponents
{
    return nil;
}

- (NSDate *)modificationDate
{
    return _modificationDate;
}

- (id<NSCoding>)persistentIdentifier
{
    return (id<NSCoding>)_identifier;
}

- (BOOL)isConflict
{
    return NO;
}

- (BOOL)isResolved
{
    return _isResolved;
}

- (void)setResolved:(BOOL)resolved
{
    if (!resolved && _isResolved) {
        [NSException raise:NSInvalidArgumentException format:@"A resolved NSFileVersion cannot be made unresolved"];
    }
    _isResolved = resolved;
}

- (BOOL)isDiscardable
{
    return _isDiscardable;
}

- (void)setDiscardable:(BOOL)discardable
{
    if (_isCurrent) {
        [NSException raise:NSInvalidArgumentException format:@"The current version of a file cannot be made discardable"];
    }
    if (!discardable && _isDiscardable) {
        [NSException raise:NSInvalidArgumentException format:@"A discardable NSFileVersion cannot be made undiscardable"];
    }
    _isDiscardable = discardable;
}

- (BOOL)hasLocalContents
{
    return YES;
}

- (BOOL)hasThumbnail
{
    return NO;
}

- (NSURL *)replaceItemAtURL:(NSURL *)url options:(NSFileVersionReplacingOptions)options error:(NSError **)error
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *failure = nil;
    NSString *destination = [url path];

    if (_isCurrent && [[_contentsURL path] isEqualToString:destination]) {
        return url;
    }
    if (![fm fileExistsAtPath:[_contentsURL path]]) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:nil];
        }
        return nil;
    }
    if ([fm fileExistsAtPath:destination] && ![fm removeItemAtPath:destination error:&failure]) {
        if (error != NULL) *error = failure;
        return nil;
    }
    BOOL ok;
    if (options & NSFileVersionReplacingByMoving) {
        ok = [fm moveItemAtPath:[_contentsURL path] toPath:destination error:&failure];
    } else {
        ok = [fm copyItemAtPath:[_contentsURL path] toPath:destination error:&failure];
    }
    if (!ok) {
        if (error != NULL) *error = failure;
        return nil;
    }
    return url;
}

- (BOOL)removeAndReturnError:(NSError **)outError
{
    if (_isCurrent) {
        [NSException raise:NSInvalidArgumentException format:@"The current version of a file cannot be removed"];
    }
    NSString *versionDir = [[_contentsURL path] stringByDeletingLastPathComponent];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:versionDir] &&
        ![[NSFileManager defaultManager] removeItemAtPath:versionDir error:&error]) {
        if (outError != NULL) *outError = error;
        return NO;
    }
    return YES;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    if (![other isKindOfClass:[NSFileVersion class]]) {
        return NO;
    }
    NSFileVersion *o = other;
    return _isCurrent == o->_isCurrent &&
           [[_fileURL path] isEqualToString:[o->_fileURL path]] &&
           [_identifier isEqualToString:o->_identifier];
}

- (NSUInteger)hash
{
    return [_identifier hash] ^ [[_fileURL path] hash];
}

@end
