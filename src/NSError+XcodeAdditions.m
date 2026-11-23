#import <Foundation/NSError+XcodeAdditions.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Block.h>
#import <pthread.h>

typedef id (^XCUserInfoValueProvider)(NSError *err, NSErrorUserInfoKey userInfoKey);

static NSMutableDictionary *XCProviders = nil;
static pthread_mutex_t XCProvidersLock = PTHREAD_MUTEX_INITIALIZER;

@implementation NSError (XcodeAdditions)

+ (void)setUserInfoValueProviderForDomain:(NSErrorDomain)errorDomain provider:(id (^)(NSError *err, NSErrorUserInfoKey userInfoKey))provider
{
    if (errorDomain == nil)
    {
        return;
    }
    pthread_mutex_lock(&XCProvidersLock);
    if (XCProviders == nil)
    {
        XCProviders = [[NSMutableDictionary alloc] init];
    }
    if (provider != nil)
    {
        XCUserInfoValueProvider copied = Block_copy(provider);
        [XCProviders setObject:copied forKey:errorDomain];
        Block_release(copied);
    }
    else
    {
        [XCProviders removeObjectForKey:errorDomain];
    }
    pthread_mutex_unlock(&XCProvidersLock);
}

+ (id (^)(NSError *err, NSErrorUserInfoKey userInfoKey))userInfoValueProviderForDomain:(NSErrorDomain)errorDomain
{
    if (errorDomain == nil)
    {
        return nil;
    }
    XCUserInfoValueProvider provider = nil;
    pthread_mutex_lock(&XCProvidersLock);
    provider = [[XCProviders objectForKey:errorDomain] retain];
    pthread_mutex_unlock(&XCProvidersLock);
    return [provider autorelease];
}

@end
