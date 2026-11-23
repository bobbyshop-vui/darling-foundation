#import <Foundation/Foundation.h>
#import <Foundation/NSGeometry.h>

#if __OBJC2__

NS_ASSUME_NONNULL_BEGIN

@class NSProgress;

typedef void (^NSItemProviderCompletionHandler)(__nullable id <NSSecureCoding> item, NSError * __null_unspecified error);
typedef void (^NSItemProviderLoadHandler)(__null_unspecified NSItemProviderCompletionHandler completionHandler, __null_unspecified Class expectedValueClass, NSDictionary * __null_unspecified options);

typedef NS_ENUM(NSInteger, NSItemProviderRepresentationVisibility) {
    NSItemProviderRepresentationVisibilityAll = 0,
    NSItemProviderRepresentationVisibilityTeam = 1,
    NSItemProviderRepresentationVisibilityGroup = 2,
    NSItemProviderRepresentationVisibilityOwnProcess = 3,
};

@protocol NSItemProviderWriting <NSObject>
+ (NSArray *)writableTypeIdentifiersForItemProvider;
- (NSProgress *)loadDataWithTypeIdentifier:(NSString *)typeIdentifier forItemProviderCompletionHandler:(void (^)(NSData *data, NSError *error))completionHandler;
@end

@protocol NSItemProviderReading <NSObject>
+ (NSArray *)readableTypeIdentifiersForItemProvider;
+ (nullable instancetype)objectWithItemProviderData:(NSData *)data typeIdentifier:(NSString *)typeIdentifier error:(NSError **)error;
@end

NS_CLASS_AVAILABLE(10_10, 8_0)
@interface NSItemProvider : NSObject <NSCopying>
{
    NSMutableArray *_representations;
}

- (instancetype)initWithItem:(nullable id <NSSecureCoding>)item typeIdentifier:(nullable NSString *)typeIdentifier NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithContentsOfURL:(null_unspecified NSURL *)fileURL;

- (BOOL)canLoadObjectOfClass:(Class<NSItemProviderReading>)aClass;
- (NSProgress *)loadObjectOfClass:(Class<NSItemProviderReading>)aClass completionHandler:(void (^)(id<NSItemProviderReading> object, NSError *error))completionHandler;
- (void)registerObjectOfClass:(Class<NSItemProviderWriting>)aClass visibility:(NSItemProviderRepresentationVisibility)visibility loadHandler:(NSProgress * _Nullable (^)(void (^completionHandler)(id<NSItemProviderWriting> object, NSError *error)))loadHandler;

@property(readonly) NSRect containerFrame;
@property(readonly) NSRect sourceFrame;

- (void)registerItemForTypeIdentifier:(NSString *)typeIdentifier loadHandler:(NSItemProviderLoadHandler)loadHandler;

@property(copy, readonly, NS_NONATOMIC_IOSONLY) NSArray *registeredTypeIdentifiers;

- (BOOL)hasItemConformingToTypeIdentifier:(NSString *)typeIdentifier;

- (void)loadItemForTypeIdentifier:(NSString *)typeIdentifier options:(nullable NSDictionary *)options completionHandler:(nullable NSItemProviderCompletionHandler)completionHandler;

@end

FOUNDATION_EXTERN NSString * __null_unspecified const NSItemProviderPreferredImageSizeKey NS_AVAILABLE(10_10, 8_0);

@interface NSItemProvider(NSPreviewSupport)

@property(nullable, copy, NS_NONATOMIC_IOSONLY) NSItemProviderLoadHandler previewImageHandler NS_AVAILABLE(10_10, 8_0);

- (void)loadPreviewImageWithOptions:(null_unspecified NSDictionary *)options completionHandler:(null_unspecified NSItemProviderCompletionHandler)completionHandler NS_AVAILABLE(10_10, 8_0);

@end

FOUNDATION_EXTERN NSString * __null_unspecified const NSExtensionJavaScriptPreprocessingResultsKey NS_AVAILABLE(10_10, 8_0);

FOUNDATION_EXTERN NSString * __null_unspecified const NSExtensionJavaScriptFinalizeArgumentKey NS_AVAILABLE_IOS(8_0);

FOUNDATION_EXTERN NSString * __null_unspecified const NSItemProviderErrorDomain NS_AVAILABLE(10_10, 8_0);

typedef NS_ENUM(NSInteger, NSItemProviderErrorCode) {
    NSItemProviderUnknownError                                      = -1,
    NSItemProviderItemUnavailableError                              = -1000,
    NSItemProviderUnexpectedValueClassError                         = -1100,
    NSItemProviderUnavailableCoercionError NS_AVAILABLE(10_11, 9_0) = -1200
} NS_ENUM_AVAILABLE(10_10, 8_0);

NS_ASSUME_NONNULL_END

#endif

