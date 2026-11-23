#import <Foundation/NSPersonNameComponentsFormatter.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSMutableAttributedString.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>

NSString * const NSPersonNameComponentKey = @"NSPersonNameComponentKey";
NSString * const NSPersonNameComponentGivenName = @"NSPersonNameComponentGivenName";
NSString * const NSPersonNameComponentFamilyName = @"NSPersonNameComponentFamilyName";
NSString * const NSPersonNameComponentMiddleName = @"NSPersonNameComponentMiddleName";
NSString * const NSPersonNameComponentPrefix = @"NSPersonNameComponentPrefix";
NSString * const NSPersonNameComponentSuffix = @"NSPersonNameComponentSuffix";
NSString * const NSPersonNameComponentNickname = @"NSPersonNameComponentNickname";
NSString * const NSPersonNameComponentDelimiter = @"NSPersonNameComponentDelimiter";

static BOOL NSPNCNonEmpty(NSString *s)
{
    return s != nil && [s length] > 0;
}

static NSString *NSPNCInitial(NSString *s)
{
    if (!NSPNCNonEmpty(s)) {
        return nil;
    }
    NSRange r = [s rangeOfComposedCharacterSequenceAtIndex:0];
    return [[s substringWithRange:r] uppercaseString];
}

@implementation NSPersonNameComponentsFormatter

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (NSString *)localizedStringFromPersonNameComponents:(NSPersonNameComponents *)components
                                                style:(NSPersonNameComponentsFormatterStyle)style
                                              options:(NSPersonNameComponentsFormatterOptions)options
{
    NSPersonNameComponentsFormatter *formatter = [[[self alloc] init] autorelease];
    [formatter setStyle:style];
    [formatter setPhonetic:(options & NSPersonNameComponentsFormatterPhonetic) != 0];
    return [formatter stringFromPersonNameComponents:components];
}

- (NSPersonNameComponentsFormatterStyle)style
{
    return _style;
}

- (void)setStyle:(NSPersonNameComponentsFormatterStyle)style
{
    _style = style;
}

- (BOOL)isPhonetic
{
    return _phonetic;
}

- (void)setPhonetic:(BOOL)phonetic
{
    _phonetic = phonetic;
}

/* Returns an array of {text, componentKey} pairs, in display order, for the receiver's style. */
- (NSArray *)partsForComponents:(NSPersonNameComponents *)components
{
    if (_phonetic) {
        NSPersonNameComponents *phonetic = [components phoneticRepresentation];
        if (phonetic != nil) {
            components = phonetic;
        }
    }

    NSString *prefix = [components namePrefix];
    NSString *given = [components givenName];
    NSString *middle = [components middleName];
    NSString *family = [components familyName];
    NSString *suffix = [components nameSuffix];
    NSString *nickname = [components nickname];
    NSMutableArray *parts = [NSMutableArray array];

    void (^add)(NSString *, NSString *) = ^(NSString *text, NSString *key) {
        if (NSPNCNonEmpty(text)) {
            [parts addObject:[NSArray arrayWithObjects:text, key, nil]];
        }
    };

    switch (_style) {
    case NSPersonNameComponentsFormatterStyleShort:
        if (NSPNCNonEmpty(nickname)) {
            add(nickname, NSPersonNameComponentNickname);
        } else if (NSPNCNonEmpty(given)) {
            add(given, NSPersonNameComponentGivenName);
        } else {
            add(family, NSPersonNameComponentFamilyName);
        }
        break;
    case NSPersonNameComponentsFormatterStyleLong:
        add(prefix, NSPersonNameComponentPrefix);
        add(given, NSPersonNameComponentGivenName);
        add(middle, NSPersonNameComponentMiddleName);
        add(family, NSPersonNameComponentFamilyName);
        add(suffix, NSPersonNameComponentSuffix);
        break;
    case NSPersonNameComponentsFormatterStyleAbbreviated:
        add(NSPNCInitial(given), NSPersonNameComponentGivenName);
        add(NSPNCInitial(middle), NSPersonNameComponentMiddleName);
        add(NSPNCInitial(family), NSPersonNameComponentFamilyName);
        break;
    case NSPersonNameComponentsFormatterStyleDefault:
    case NSPersonNameComponentsFormatterStyleMedium:
    default:
        add(given, NSPersonNameComponentGivenName);
        add(family, NSPersonNameComponentFamilyName);
        break;
    }
    return parts;
}

- (NSString *)stringFromPersonNameComponents:(NSPersonNameComponents *)components
{
    NSArray *parts = [self partsForComponents:components];
    NSString *separator = (_style == NSPersonNameComponentsFormatterStyleAbbreviated) ? @"" : @" ";
    NSMutableString *result = [NSMutableString string];
    for (NSArray *part in parts) {
        if ([result length] > 0) {
            [result appendString:separator];
        }
        [result appendString:[part objectAtIndex:0]];
    }
    return result;
}

- (NSAttributedString *)annotatedStringFromPersonNameComponents:(NSPersonNameComponents *)components
{
    NSArray *parts = [self partsForComponents:components];
    NSString *separator = (_style == NSPersonNameComponentsFormatterStyleAbbreviated) ? @"" : @" ";
    NSMutableAttributedString *result = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
    BOOL first = YES;
    for (NSArray *part in parts) {
        if (!first && [separator length] > 0) {
            [result appendAttributedString:[[[NSAttributedString alloc] initWithString:separator] autorelease]];
        }
        first = NO;
        NSDictionary *attrs = [NSDictionary dictionaryWithObject:[part objectAtIndex:1] forKey:NSPersonNameComponentKey];
        [result appendAttributedString:[[[NSAttributedString alloc] initWithString:[part objectAtIndex:0]
                                                                        attributes:attrs] autorelease]];
    }
    return result;
}

- (NSPersonNameComponents *)personNameComponentsFromString:(NSString *)string
{
    NSArray *words = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray *tokens = [NSMutableArray array];
    for (NSString *word in words) {
        if ([word length] > 0) {
            [tokens addObject:word];
        }
    }
    if ([tokens count] == 0) {
        return nil;
    }

    NSPersonNameComponents *components = [[[NSPersonNameComponents alloc] init] autorelease];
    NSUInteger count = [tokens count];
    if (count == 1) {
        [components setGivenName:[tokens objectAtIndex:0]];
    } else {
        [components setGivenName:[tokens objectAtIndex:0]];
        [components setFamilyName:[tokens objectAtIndex:count - 1]];
        if (count > 2) {
            NSRange middleRange = NSMakeRange(1, count - 2);
            [components setMiddleName:[[tokens subarrayWithRange:middleRange] componentsJoinedByString:@" "]];
        }
    }
    return components;
}

- (NSString *)stringForObjectValue:(id)obj
{
    if (![obj isKindOfClass:[NSPersonNameComponents class]]) {
        return nil;
    }
    return [self stringFromPersonNameComponents:obj];
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs
{
    if (![obj isKindOfClass:[NSPersonNameComponents class]]) {
        return nil;
    }
    return [self annotatedStringFromPersonNameComponents:obj];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error
{
    NSPersonNameComponents *components = [self personNameComponentsFromString:string];
    if (components == nil) {
        if (error != NULL) {
            *error = @"Unable to parse a person name from the string.";
        }
        return NO;
    }
    if (obj != NULL) {
        *obj = components;
    }
    return YES;
}

- (id)copyWithZone:(NSZone *)zone
{
    NSPersonNameComponentsFormatter *copy = [[[self class] allocWithZone:zone] init];
    copy->_style = _style;
    copy->_phonetic = _phonetic;
    return copy;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder])) {
        _style = (NSPersonNameComponentsFormatterStyle)[coder decodeIntegerForKey:@"NS.style"];
        _phonetic = [coder decodeBoolForKey:@"NS.phonetic"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeInteger:_style forKey:@"NS.style"];
    [coder encodeBool:_phonetic forKey:@"NS.phonetic"];
}

@end
