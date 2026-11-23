#import <Foundation/NSObject.h>

@class NSBundle, NSError, NSProgress, NSSet<ObjectType>, NSString;

NS_ASSUME_NONNULL_BEGIN

@interface NSBundleResourceRequest : NSObject {
    NSSet *_tags;
    NSBundle *_bundle;
    NSProgress *_progress;
    double _loadingPriority;
    BOOL _accessing;
    BOOL _used;
}

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTags:(NSSet<NSString *> *)tags;
- (instancetype)initWithTags:(NSSet<NSString *> *)tags bundle:(NSBundle *)bundle NS_DESIGNATED_INITIALIZER;

@property double loadingPriority;
@property (readonly, copy) NSSet<NSString *> *tags;
@property (readonly, strong) NSBundle *bundle;

- (void)beginAccessingResourcesWithCompletionHandler:(void (^)(NSError * _Nullable error))completionHandler;
- (void)conditionallyBeginAccessingResourcesWithCompletionHandler:(void (^)(BOOL resourcesAvailable))completionHandler;
- (void)endAccessingResources;

@property (readonly, strong) NSProgress *progress;

@end

NS_ASSUME_NONNULL_END
