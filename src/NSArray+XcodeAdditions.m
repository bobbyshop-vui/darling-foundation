#import <Foundation/NSArray+XcodeAdditions.h>
#import <Foundation/NSData.h>
#import <Foundation/NSError.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSURL.h>

@implementation NSArray (XcodeAdditions)

- (NSArray *)initWithContentsOfURL:(NSURL *)url error:(NSError **)error
{
    BOOL mutableResult = [self isKindOfClass:[NSMutableArray class]];
    NSError *localError = nil;
    NSArray *result = nil;

    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&localError];
    if (data != nil)
    {
        NSPropertyListMutabilityOptions options = mutableResult ? NSPropertyListMutableContainers : NSPropertyListImmutable;
        id plist = [NSPropertyListSerialization propertyListWithData:data options:options format:NULL error:&localError];
        if ([plist isKindOfClass:[NSArray class]])
        {
            result = [plist retain];
        }
        else if (plist != nil)
        {
            localError = [NSError errorWithDomain:NSCocoaErrorDomain code:kCFPropertyListReadCorruptError userInfo:nil];
        }
    }

    [self release];
    if (result == nil && error != NULL)
    {
        *error = localError;
    }
    return result;
}

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
