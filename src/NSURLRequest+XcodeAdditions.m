#import <Foundation/NSURLRequest+XcodeAdditions.h>

@implementation NSURLRequest (XcodeAdditions)

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
