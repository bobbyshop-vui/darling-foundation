#import <Foundation/NSOrderedSet.h>

@class NSArray;

/* In-place sort-descriptor sorting for mutable ordered sets (macOS 10.7 SDK). */
@interface NSMutableOrderedSet (XcodeAdditions)

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors;

@end
