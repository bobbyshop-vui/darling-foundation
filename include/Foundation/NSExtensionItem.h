#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@class NSArray<ObjectType>, NSAttributedString, NSDictionary, NSItemProvider;

NS_ASSUME_NONNULL_BEGIN

@interface NSExtensionItem : NSObject <NSCopying, NSSecureCoding> {
    NSAttributedString *_attributedTitle;
    NSAttributedString *_attributedContentText;
    NSArray *_attachments;
    NSDictionary *_userInfo;
}

@property (nullable, copy) NSAttributedString *attributedTitle;
@property (nullable, copy) NSAttributedString *attributedContentText;
@property (nullable, copy) NSArray<NSItemProvider *> *attachments;
@property (nullable, copy) NSDictionary *userInfo;

@end

FOUNDATION_EXTERN NSString * _Null_unspecified const NSExtensionItemAttributedTitleKey;
FOUNDATION_EXTERN NSString * _Null_unspecified const NSExtensionItemAttributedContentTextKey;
FOUNDATION_EXTERN NSString * _Null_unspecified const NSExtensionItemAttachmentsKey;

NS_ASSUME_NONNULL_END
