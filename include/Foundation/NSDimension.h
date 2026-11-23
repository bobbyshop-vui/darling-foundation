#import <Foundation/NSUnit.h>

@class NSUnitConverter;

@interface NSDimension : NSUnit {
    NSString *_dimensionSymbol;
    NSUnitConverter *_dimensionConverter;
}

+ (instancetype)baseUnit;
- (instancetype)initWithSymbol:(NSString *)symbol converter:(NSUnitConverter *)converter;

@end
