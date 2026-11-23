#import <Foundation/NSOrderedSet.h>

@class NSArray;

/* Sort-descriptor sorting for ordered sets (macOS 10.7 SDK). */
@interface NSOrderedSet (XcodeAdditions)

- (NSArray *)sortedArrayUsingDescriptors:(NSArray *)sortDescriptors;

@end
