#import <Foundation/NSUnit.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <objc/runtime.h>

@implementation NSUnit

- (instancetype)initWithSymbol:(NSString *)symbol
{
    if (symbol == nil) {
        [self release];
        [NSException raise:NSInvalidArgumentException format:@"NSUnit symbol must not be nil"];
        return nil;
    }

    self = [super init];
    if (self)
        _symbol = [symbol copy];
    return self;
}

- (NSString *)symbol
{
    if (_symbol != nil)
        return _symbol;

    if (class_getInstanceVariable([self class], "_dimensionSymbol") != NULL) {
        void *dimensionSymbol = NULL;
        object_getInstanceVariable(self, "_dimensionSymbol", &dimensionSymbol);
        return (NSString *)dimensionSymbol;
    }
    return nil;
}

- (void)dealloc
{
    [_symbol release];
    [super dealloc];
}

@end
