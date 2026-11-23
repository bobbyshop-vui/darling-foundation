#import <Foundation/NSFormatter.h>
#import <Foundation/NSLocale.h>

typedef NS_ENUM(NSInteger, NSFormattingUnitStyle) {
    NSFormattingUnitStyleShort = 1,
    NSFormattingUnitStyleMedium = 2,
    NSFormattingUnitStyleLong = 3,
};

@interface NSMeasurementFormatter : NSFormatter
{
@private
    NSLocale *_locale;
    NSFormattingUnitStyle _unitStyle;
}

- (NSLocale *)locale;
- (void)setLocale:(NSLocale *)locale;
- (void)setUnitStyle:(NSFormattingUnitStyle)unitStyle;
- (NSFormattingUnitStyle)unitStyle;

@end
