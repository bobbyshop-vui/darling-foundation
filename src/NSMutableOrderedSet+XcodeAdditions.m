#import <Foundation/NSMutableOrderedSet+XcodeAdditions.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSSortDescriptor.h>

@implementation NSMutableOrderedSet (XcodeAdditions)

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors
{
    if ([sortDescriptors count] == 0 || [self count] < 2)
    {
        return;
    }
    NSArray *sorted = [[[self array] sortedArrayUsingDescriptors:sortDescriptors] retain];
    [self removeAllObjects];
    [self addObjectsFromArray:sorted];
    [sorted release];
}

@end
