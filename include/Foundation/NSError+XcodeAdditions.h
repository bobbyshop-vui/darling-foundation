#import <Foundation/NSError.h>

/* Registry for NSError user-info value providers (macOS 10.11 SDK). */
@interface NSError (XcodeAdditions)

+ (void)setUserInfoValueProviderForDomain:(NSErrorDomain)errorDomain provider:(id (^)(NSError *err, NSErrorUserInfoKey userInfoKey))provider;
+ (id (^)(NSError *err, NSErrorUserInfoKey userInfoKey))userInfoValueProviderForDomain:(NSErrorDomain)errorDomain;

@end
