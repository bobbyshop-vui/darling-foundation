#import <Foundation/NSRange.h>
#import <Foundation/NSObject.h>

@interface NSIndexPath : NSObject <NSCopying, NSCoding>
{
    NSUInteger *_indexes;
    NSUInteger _hash;
    NSUInteger _length;
}

+ (instancetype)indexPathWithIndex:(NSUInteger)index;
+ (instancetype)indexPathForItem:(NSInteger)item inSection:(NSInteger)section;
+ (instancetype)indexPathWithIndexes:(const NSUInteger [])indexes length:(NSUInteger)length;
- (instancetype)initWithIndex:(NSUInteger)index;
- (instancetype)initWithIndexes:(const NSUInteger [])indexes length:(NSUInteger)length;
- (NSIndexPath *)indexPathByAddingIndex:(NSUInteger)index;
- (NSIndexPath *)indexPathByRemovingLastIndex;
- (NSUInteger)indexAtPosition:(NSUInteger)position;
- (NSUInteger)length;
- (void)getIndexes:(NSUInteger *)indexes;
- (void)getIndexes:(NSUInteger *)indexes range:(NSRange)positionRange;
@property (readonly) NSInteger item;
@property (readonly) NSInteger section;
- (NSComparisonResult)compare:(NSIndexPath *)otherObject;

@end
