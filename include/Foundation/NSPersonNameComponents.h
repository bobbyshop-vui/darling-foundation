#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSPersonNameComponents : NSObject <NSCopying, NSSecureCoding> {
    NSString *_namePrefix;
    NSString *_givenName;
    NSString *_middleName;
    NSString *_familyName;
    NSString *_nameSuffix;
    NSString *_nickname;
    NSPersonNameComponents *_phoneticRepresentation;
}

@property (copy, nullable) NSString *namePrefix;
@property (copy, nullable) NSString *givenName;
@property (copy, nullable) NSString *middleName;
@property (copy, nullable) NSString *familyName;
@property (copy, nullable) NSString *nameSuffix;
@property (copy, nullable) NSString *nickname;
@property (copy, nullable) NSPersonNameComponents *phoneticRepresentation;

@end

NS_ASSUME_NONNULL_END
