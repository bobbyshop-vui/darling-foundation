#import <Foundation/NSCharacterSet+XcodeAdditions.h>
#import <dispatch/dispatch.h>
#import <Foundation/NSString.h>

// RFC 3986 building blocks, as used by Apple's URL component character sets.
static NSString *const XCUnreserved = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
static NSString *const XCSubDelims = @"!$&'()*+,;=";

static NSCharacterSet *XCURLSet(NSString *extra)
{
    NSMutableCharacterSet *set = [[NSMutableCharacterSet alloc] init];
    [set addCharactersInString:XCUnreserved];
    [set addCharactersInString:XCSubDelims];
    [set addCharactersInString:extra];
    NSCharacterSet *immutable = [set copy];
    [set release];
    return immutable;
}

@implementation NSCharacterSet (XcodeAdditions)

+ (NSCharacterSet *)URLUserAllowedCharacterSet
{
    static NSCharacterSet *set;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ set = XCURLSet(@""); });
    return set;
}

+ (NSCharacterSet *)URLPasswordAllowedCharacterSet
{
    static NSCharacterSet *set;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ set = XCURLSet(@""); });
    return set;
}

+ (NSCharacterSet *)URLHostAllowedCharacterSet
{
    static NSCharacterSet *set;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ set = XCURLSet(@":[]"); });
    return set;
}

+ (NSCharacterSet *)URLPathAllowedCharacterSet
{
    static NSCharacterSet *set;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ set = XCURLSet(@":@/"); });
    return set;
}

+ (NSCharacterSet *)URLQueryAllowedCharacterSet
{
    static NSCharacterSet *set;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ set = XCURLSet(@":@/?"); });
    return set;
}

+ (NSCharacterSet *)URLFragmentAllowedCharacterSet
{
    static NSCharacterSet *set;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ set = XCURLSet(@":@/?"); });
    return set;
}

@end
