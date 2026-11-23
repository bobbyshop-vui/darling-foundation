#import <Foundation/NSScriptWhoseTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSSpecifierTest : NSScriptWhoseTest {
    @private
    NSTestComparisonOperation _comparisonOperator;
    NSScriptObjectSpecifier *_object1;
    id _object2;
}

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)inCoder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithObjectSpecifier:(nullable NSScriptObjectSpecifier *)obj1 comparisonOperator:(NSTestComparisonOperation)compOp testObject:(nullable id)obj2 NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
