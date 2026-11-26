#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@class NSArray<ObjectType>, NSBundle, NSDictionary, NSError, NSExtensionContext, NSUUID;

NS_ASSUME_NONNULL_BEGIN

/* Private Apple class: an app extension discovered through PlugInKit. */
@interface NSExtension : NSObject {
    id _plugIn;
    NSUUID *_uuid;
    BOOL _optedIn;
}

+ (nullable NSExtension *)extensionWithIdentifier:(NSString *)identifier error:(NSError **)error;
+ (nullable NSArray *)extensionsWithMatchingAttributes:(NSDictionary *)attributes error:(NSError **)error;
+ (id)beginMatchingExtensionsWithAttributes:(NSDictionary *)attributes
                                 completion:(void (^)(NSArray * _Nullable extensions, NSError * _Nullable error))completion;
+ (void)endMatchingExtensions:(id)matchingContext;

- (instancetype)_initWithPKPlugin:(id)plugIn;

@property (readonly) id _plugIn;
@property (readonly, copy) NSString *identifier;
@property (readonly, copy) NSDictionary *infoDictionary;
@property (readonly, copy) NSDictionary *attributes;
@property (readonly, copy) NSString *version;
@property (readonly, copy, nullable) NSBundle *_extensionBundle;

- (nullable NSString *)localizedName;

- (void)beginExtensionRequestWithInputItems:(NSArray *)inputItems
                                 completion:(void (^)(NSUUID * _Nullable requestIdentifier))completion;
- (void)setRequestInterruptionBlock:(nullable void (^)(NSUUID *))block;
- (void)setRequestCancellationBlock:(nullable void (^)(NSUUID *, NSError *))block;
- (nullable NSExtensionContext *)_extensionContextForUUID:(NSUUID *)uuid;
- (void)cancelExtensionRequestWithIdentifier:(NSUUID *)uuid;

@end

NS_ASSUME_NONNULL_END
