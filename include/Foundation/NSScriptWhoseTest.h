#import <Foundation/NSObject.h>

@class NSArray<ObjectType>, NSScriptObjectSpecifier, NSSpecifierTest, NSString;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NSTestComparisonOperation) {
    NSEqualToComparison = 0,
    NSLessThanOrEqualToComparison,
    NSLessThanComparison,
    NSGreaterThanOrEqualToComparison,
    NSGreaterThanComparison,
    NSBeginsWithComparison,
    NSEndsWithComparison,
    NSContainsComparison
};

@interface NSScriptWhoseTest : NSObject <NSCoding>

- (BOOL)isTrue;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)inCoder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
