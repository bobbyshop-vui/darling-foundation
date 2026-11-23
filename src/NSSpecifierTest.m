#import <Foundation/NSSpecifierTest.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSScriptObjectSpecifiers.h>

@interface NSObject (NSSpecifierTestEvaluation)
- (id)objectsByEvaluatingSpecifier;
@end

static BOOL NSSpecifierTestCompare(id lhs, id rhs, NSTestComparisonOperation op)
{
    switch (op) {
    case NSEqualToComparison:
        return lhs == rhs || [lhs isEqual:rhs];
    case NSLessThanOrEqualToComparison:
    case NSLessThanComparison:
    case NSGreaterThanOrEqualToComparison:
    case NSGreaterThanComparison: {
        if (lhs == nil || rhs == nil || ![lhs respondsToSelector:@selector(compare:)]) {
            return NO;
        }
        NSComparisonResult r = (NSComparisonResult)(NSInteger)[lhs compare:rhs];
        if (op == NSLessThanOrEqualToComparison) return r != NSOrderedDescending;
        if (op == NSLessThanComparison) return r == NSOrderedAscending;
        if (op == NSGreaterThanOrEqualToComparison) return r != NSOrderedAscending;
        return r == NSOrderedDescending;
    }
    case NSBeginsWithComparison:
        if ([lhs isKindOfClass:[NSString class]] && [rhs isKindOfClass:[NSString class]]) {
            return [(NSString *)lhs hasPrefix:rhs];
        }
        if ([lhs isKindOfClass:[NSArray class]] && [(NSArray *)lhs count] > 0) {
            return [[(NSArray *)lhs objectAtIndex:0] isEqual:rhs];
        }
        return NO;
    case NSEndsWithComparison:
        if ([lhs isKindOfClass:[NSString class]] && [rhs isKindOfClass:[NSString class]]) {
            return [(NSString *)lhs hasSuffix:rhs];
        }
        if ([lhs isKindOfClass:[NSArray class]] && [(NSArray *)lhs count] > 0) {
            return [[(NSArray *)lhs lastObject] isEqual:rhs];
        }
        return NO;
    case NSContainsComparison:
        if ([lhs isKindOfClass:[NSString class]] && [rhs isKindOfClass:[NSString class]]) {
            return [(NSString *)lhs rangeOfString:rhs].location != NSNotFound;
        }
        if ([lhs isKindOfClass:[NSArray class]]) {
            return [(NSArray *)lhs containsObject:rhs];
        }
        return NO;
    }
    return NO;
}

@implementation NSSpecifierTest

- (instancetype)initWithObjectSpecifier:(NSScriptObjectSpecifier *)obj1
                     comparisonOperator:(NSTestComparisonOperation)compOp
                             testObject:(id)obj2
{
    if ((self = [super init])) {
        _object1 = [obj1 retain];
        _comparisonOperator = compOp;
        _object2 = [obj2 retain];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder])) {
        if (![coder allowsKeyedCoding]) {
            [self release];
            return nil;
        }
        _comparisonOperator = (NSTestComparisonOperation)[coder decodeIntegerForKey:@"NSComparisonOperator"];
        _object1 = [[coder decodeObjectForKey:@"NSObject1"] retain];
        _object2 = [[coder decodeObjectForKey:@"NSObject2"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    if ([coder allowsKeyedCoding]) {
        [coder encodeInteger:(NSInteger)_comparisonOperator forKey:@"NSComparisonOperator"];
        [coder encodeObject:_object1 forKey:@"NSObject1"];
        [coder encodeObject:_object2 forKey:@"NSObject2"];
    }
}

- (void)dealloc
{
    [_object1 release];
    [_object2 release];
    [super dealloc];
}

- (BOOL)isTrue
{
    if (_object1 == nil || ![_object1 respondsToSelector:@selector(objectsByEvaluatingSpecifier)]) {
        return NO;
    }
    id value = [_object1 objectsByEvaluatingSpecifier];
    if (value == nil) {
        return NO;
    }
    return NSSpecifierTestCompare(value, _object2, _comparisonOperator);
}

@end
