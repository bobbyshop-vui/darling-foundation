#import <Foundation/NSObject.h>

@class NSString;

@interface NSUnit : NSObject {
@private
    NSString *_symbol;
}

@property (readonly, copy) NSString *symbol;
- (instancetype)initWithSymbol:(NSString *)symbol;

@end
