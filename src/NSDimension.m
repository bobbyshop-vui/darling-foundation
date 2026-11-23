#import <Foundation/NSDimension.h>
#import <Foundation/NSUnitConverter.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>

@implementation NSDimension

+ (instancetype)baseUnit
{
    // Concrete dimensions (NSUnitLength, ...) must override this.
    [NSException raise:NSInvalidArgumentException
                format:@"*** +[%@ baseUnit]: subclasses of NSDimension must override +baseUnit", NSStringFromClass(self)];
    return nil;
}

- (instancetype)initWithSymbol:(NSString *)symbol converter:(NSUnitConverter *)converter
{
    self = [super init];
    if (self) {
        _dimensionSymbol = [symbol copy];
        _dimensionConverter = [converter retain];
    }
    return self;
}

- (void)dealloc
{
    [_dimensionSymbol release];
    [_dimensionConverter release];
    [super dealloc];
}

@end
