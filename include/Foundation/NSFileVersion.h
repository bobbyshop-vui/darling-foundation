#import <Foundation/NSObject.h>

@class NSArray, NSDate, NSDictionary, NSError, NSString, NSURL, NSPersonNameComponents;

typedef NS_OPTIONS(NSUInteger, NSFileVersionAddingOptions) {
    NSFileVersionAddingByMoving = 1 << 0
};

typedef NS_OPTIONS(NSUInteger, NSFileVersionReplacingOptions) {
    NSFileVersionReplacingByMoving = 1 << 0
};

@interface NSFileVersion : NSObject {
    NSURL *_fileURL;
    NSURL *_contentsURL;
    NSString *_identifier;
    BOOL _isCurrent;
    NSString *_localizedName;
    NSDate *_modificationDate;
    BOOL _isResolved;
    BOOL _isDiscardable;
}

@property (readonly) NSURL *URL;
@property (readonly) NSString *localizedName;
@property (readonly) NSString *localizedNameOfSavingComputer;
@property (readonly) NSDate *modificationDate;
@property (readonly, copy) NSPersonNameComponents *originatorNameComponents;
@property (readonly) id<NSCoding> persistentIdentifier;
@property (readonly, getter=isConflict) BOOL conflict;
@property (getter=isResolved) BOOL resolved;
@property (getter=isDiscardable) BOOL discardable;
@property (readonly) BOOL hasLocalContents;
@property (readonly) BOOL hasThumbnail;

+ (NSFileVersion *)currentVersionOfItemAtURL:(NSURL *)url;
+ (NSArray *)otherVersionsOfItemAtURL:(NSURL *)url;
+ (NSArray *)unresolvedConflictVersionsOfItemAtURL:(NSURL *)url;
+ (void)getNonlocalVersionsOfItemAtURL:(NSURL *)url completionHandler:(void (^)(NSArray *nonlocalFileVersions, NSError *error))completionHandler;
+ (NSFileVersion *)versionOfItemAtURL:(NSURL *)url forPersistentIdentifier:(id)persistentIdentifier;
+ (NSFileVersion *)addVersionOfItemAtURL:(NSURL *)url withContentsOfURL:(NSURL *)contentsURL options:(NSFileVersionAddingOptions)options error:(NSError **)outError;
+ (NSURL *)temporaryDirectoryURLForNewVersionOfItemAtURL:(NSURL *)url;
+ (BOOL)removeOtherVersionsOfItemAtURL:(NSURL *)url error:(NSError **)outError;

- (NSURL *)replaceItemAtURL:(NSURL *)url options:(NSFileVersionReplacingOptions)options error:(NSError **)error;
- (BOOL)removeAndReturnError:(NSError **)outError;

@end
