#import <Foundation/NSDictionary+XcodeAdditions.h>
#import <Foundation/NSData.h>
#import <Foundation/NSError.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSURL.h>

@implementation NSDictionary (XcodeAdditions)

- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error
{
    NSError *localError = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:self format:NSPropertyListXMLFormat_v1_0 options:0 error:&localError];
    BOOL success = NO;
    if (data != nil)
    {
        success = [data writeToURL:url options:NSDataWritingAtomic error:&localError];
    }
    if (!success && error != NULL)
    {
        *error = localError;
    }
    return success;
}

@end
