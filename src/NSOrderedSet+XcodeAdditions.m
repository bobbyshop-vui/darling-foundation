#import <Foundation/NSOrderedSet+XcodeAdditions.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSSortDescriptor.h>

@implementation NSOrderedSet (XcodeAdditions)

- (NSArray *)sortedArrayUsingDescriptors:(NSArray *)sortDescriptors
{
    return [[self array] sortedArrayUsingDescriptors:sortDescriptors];
}

@end
