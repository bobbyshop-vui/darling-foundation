#import <Foundation/NSExtensionItem.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSItemProvider.h>
#import <Foundation/NSSet.h>

NSString * const NSExtensionItemAttributedTitleKey = @"NSExtensionItemAttributedTitleKey";
NSString * const NSExtensionItemAttributedContentTextKey = @"NSExtensionItemAttributedContentTextKey";
NSString * const NSExtensionItemAttachmentsKey = @"NSExtensionItemAttachmentsKey";

@implementation NSExtensionItem

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)dealloc
{
    [_attributedTitle release];
    [_attributedContentText release];
    [_attachments release];
    [_userInfo release];
    [super dealloc];
}

- (NSAttributedString *)attributedTitle { return _attributedTitle; }
- (NSAttributedString *)attributedContentText { return _attributedContentText; }
- (NSArray<NSItemProvider *> *)attachments { return _attachments; }
- (NSDictionary *)userInfo { return _userInfo; }

- (void)setAttributedTitle:(NSAttributedString *)value
{
    if (_attributedTitle != value) {
        [_attributedTitle release];
        _attributedTitle = [value copy];
    }
}

- (void)setAttributedContentText:(NSAttributedString *)value
{
    if (_attributedContentText != value) {
        [_attributedContentText release];
        _attributedContentText = [value copy];
    }
}

- (void)setAttachments:(NSArray<NSItemProvider *> *)value
{
    if (_attachments != value) {
        [_attachments release];
        _attachments = [value copy];
    }
}

- (void)setUserInfo:(NSDictionary *)value
{
    if (_userInfo != value) {
        [_userInfo release];
        _userInfo = [value copy];
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    NSExtensionItem *copy = [[[self class] allocWithZone:zone] init];
    [copy setAttributedTitle:_attributedTitle];
    [copy setAttributedContentText:_attributedContentText];
    [copy setAttachments:_attachments];
    [copy setUserInfo:_userInfo];
    return copy;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init])) {
        _attributedTitle = [[coder decodeObjectOfClass:[NSAttributedString class] forKey:NSExtensionItemAttributedTitleKey] copy];
        _attributedContentText = [[coder decodeObjectOfClass:[NSAttributedString class] forKey:NSExtensionItemAttributedContentTextKey] copy];
        NSSet *arrayClasses = [NSSet setWithObjects:[NSArray class], [NSItemProvider class], nil];
        _attachments = [[coder decodeObjectOfClasses:arrayClasses forKey:NSExtensionItemAttachmentsKey] copy];
        NSSet *plistClasses = [NSSet setWithObjects:[NSDictionary class], [NSArray class], [NSString class],
                               [NSNumber class], [NSData class], [NSDate class], nil];
        _userInfo = [[coder decodeObjectOfClasses:plistClasses forKey:@"NSExtensionItemUserInfoKey"] copy];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_attributedTitle forKey:NSExtensionItemAttributedTitleKey];
    [coder encodeObject:_attributedContentText forKey:NSExtensionItemAttributedContentTextKey];
    [coder encodeObject:_attachments forKey:NSExtensionItemAttachmentsKey];
    [coder encodeObject:_userInfo forKey:@"NSExtensionItemUserInfoKey"];
}

@end
