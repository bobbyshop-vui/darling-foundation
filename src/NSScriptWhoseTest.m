#import <Foundation/NSScriptWhoseTest.h>
#import <Foundation/NSCoder.h>

@implementation NSScriptWhoseTest

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    /* The abstract test carries no state of its own. */
    return [super init];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
}

- (BOOL)isTrue
{
    /* An abstract test with no conditions matches nothing. */
    return NO;
}

@end
