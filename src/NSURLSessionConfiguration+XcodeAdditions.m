#import <Foundation/NSURLSessionConfiguration+XcodeAdditions.h>

@implementation NSURLSessionConfiguration (XcodeAdditions)

+ (NSURLSessionConfiguration *)ephemeralSessionConfiguration
{
    // Ephemeral sessions have no identifier and use no persistent storage.
    NSURLSessionConfiguration *configuration = [[[NSURLSessionConfiguration alloc] init] autorelease];
    configuration.timeoutIntervalForRequest = 60.0;
    configuration.timeoutIntervalForResource = 7.0 * 24.0 * 60.0 * 60.0;
    configuration.allowsCellularAccess = YES;
    configuration.HTTPShouldSetCookies = YES;
    configuration.HTTPMaximumConnectionsPerHost = 4;
    configuration.HTTPCookieStorage = nil;
    configuration.URLCredentialStorage = nil;
    return configuration;
}

@end
