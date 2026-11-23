#import <Foundation/NSObject.h>
#import <Foundation/NSZone.h>
#import <Security/Security.h>

@class NSString, NSArray;

typedef NS_ENUM(NSUInteger, NSURLCredentialPersistence) {
    NSURLCredentialPersistenceNone,
    NSURLCredentialPersistenceForSession,
    NSURLCredentialPersistencePermanent
};

@interface NSURLCredential : NSObject <NSSecureCoding, NSCopying> {
    NSString *_user;
    NSString *_password;
    NSURLCredentialPersistence _persistence;
    SecIdentityRef _identity;
    NSArray *_certificates;
    SecTrustRef _trust;
}

- (NSURLCredentialPersistence)persistence;

@end

@interface NSURLCredential (NSInternetPassword)

+ (NSURLCredential *)credentialWithUser:(NSString *)user password:(NSString *)password persistence:(NSURLCredentialPersistence)persistence;
- (id)initWithUser:(NSString *)user password:(NSString *)password persistence:(NSURLCredentialPersistence)persistence;
- (NSString *)user;
- (NSString *)password;
- (BOOL)hasPassword;

@end

@interface NSURLCredential (NSClientCertificate)

+ (NSURLCredential *)credentialWithIdentity:(SecIdentityRef)identity certificates:(NSArray *)certArray persistence:(NSURLCredentialPersistence)persistence NS_AVAILABLE(10_6, 3_0);
- (id)initWithIdentity:(SecIdentityRef)identity certificates:(NSArray *)certArray persistence:(NSURLCredentialPersistence) persistence NS_AVAILABLE(10_6, 3_0);
- (SecIdentityRef)identity;
- (NSArray *)certificates;

@end

@interface NSURLCredential(NSServerTrust)

+ (NSURLCredential *)credentialForTrust:(SecTrustRef)trust;
- (id)initWithTrust:(SecTrustRef)trust;

@end
