#import <Foundation/NSMeasurementFormatter.h>

@implementation NSMeasurementFormatter

- (NSLocale *)locale
{
    return _locale ?: [NSLocale currentLocale];
}

- (void)setLocale:(NSLocale *)locale
{
    if (_locale != locale)
    {
        [_locale release];
        _locale = [locale copy];
    }
}

- (void)setUnitStyle:(NSFormattingUnitStyle)unitStyle
{
    _unitStyle = unitStyle;
}

- (NSFormattingUnitStyle)unitStyle
{
    return _unitStyle == 0 ? NSFormattingUnitStyleMedium : _unitStyle;
}

- (void)dealloc
{
    [_locale release];
    [super dealloc];
}

@end
