//
//  NSAttributedString.m
//  Foundation
//
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/NSAttributedString.h>
#import "NSAttributedStringInternal.h"
#import "NSStringInternal.h"
#import <Foundation/NSPortCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <dispatch/dispatch.h>

@implementation NSAttributedString

@end

@implementation NSMutableAttributedString

@end
CF_PRIVATE
@interface NSMutableStringProxyForMutableAttributedString : NSMutableString
{
    NSMutableAttributedString *_owner;
}
- (id)initWithMutableAttributedString:(NSMutableAttributedString *)owner;
@end

@implementation NSAttributedString (NSAttributedString)

OBJC_PROTOCOL_IMPL_PUSH
- (NSString *)string
{
    NSRequestConcreteImplementation();
    return nil;
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
    NSRequestConcreteImplementation();
    return nil;
}
OBJC_PROTOCOL_IMPL_POP

@end

@implementation NSAttributedString (NSExtendedAttributedString)

+ (id)allocWithZone:(NSZone *)zone
{
    if (self == [NSMutableAttributedString class])
    {
        return [__NSPlaceholderAttributedString mutablePlaceholder];
    }
    else if (self == [NSAttributedString class])
    {
        return [__NSPlaceholderAttributedString immutablePlaceholder];
    }
    else
    {
        return [super allocWithZone:zone];
    }
}

- (id)initWithString:(NSString *)str
{
    return [self initWithString:str attributes:[NSDictionary dictionary]];
}

// Instances of NSAttributedString and NSMutableAttributedString are created by
// the placeholder, which has its own initializers. These are reached only by
// subclasses, which are given the same CoreFoundation backed storage.
- (id)initWithString:(NSString *)str attributes:(NSDictionary *)attrs
{
    Class storageClass = [self isKindOfClass:[NSMutableAttributedString class]] ? [NSMutableAttributedString class] : [NSAttributedString class];
    [self release];
    return [[storageClass alloc] initWithString:str attributes:attrs];
}

- (id)initWithAttributedString:(NSAttributedString *)attrStr
{
    Class storageClass = [self isKindOfClass:[NSMutableAttributedString class]] ? [NSMutableAttributedString class] : [NSAttributedString class];
    [self release];
    return [[storageClass alloc] initWithAttributedString:attrStr];
}

- (NSAttributedString *)attributedSubstringFromRange:(NSRange)range
{
    NSString *s = [self string];
    NSUInteger length = [s length];
    if ((uint64_t)range.location + range.length > length)
    {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"range (%d,%d) beyond NSAttributedString bounds (%d)", range.location, range.length, [self length]] userInfo:nil];
    }
    NSString *substring = [s substringWithRange:range];
    NSMutableAttributedString *obj = [[[NSMutableAttributedString alloc] initWithString:substring] autorelease];

    NSUInteger delta = range.location;
    NSUInteger newLength;

    for (NSUInteger i = 0; i < range.length; i = i + newLength)
    {
        NSRange effRange;
        NSUInteger selfIndex = i + delta;
        NSDictionary *attrs = [self attributesAtIndex:selfIndex effectiveRange:&effRange];
        newLength = effRange.length;
        if (effRange.location < selfIndex)
        {
            newLength -= selfIndex - effRange.location;
        }
        if (newLength > range.length - i)
        {
            newLength = range.length - i;
        }
        [obj addAttributes:attrs range:NSMakeRange(i, newLength)];
    }
    return obj;
}

- (void)enumerateAttributesInRange:(NSRange)enumerationRange options:(NSAttributedStringEnumerationOptions)opts usingBlock:(void (^)(NSDictionary *attrs, NSRange range, BOOL *stop))block
{
    if ((uint64_t)enumerationRange.location + enumerationRange.length > [self length])
    {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"range (%d,%d) beyond NSAttributedString bounds (%d)", enumerationRange.location, enumerationRange.length, [self length]] userInfo:nil];
    }
    if (enumerationRange.length == 0)
    {
        return;
    }
    if (opts & NSAttributedStringEnumerationReverse)
    {
        NSUInteger previous;
        NSUInteger limit = enumerationRange.location;
        for (NSUInteger i = enumerationRange.location + enumerationRange.length - 1; i >= limit; i = previous)
        {
            NSRange effRange;
            BOOL stop = NO;
            NSDictionary *dict;
            if (opts & NSAttributedStringEnumerationLongestEffectiveRangeNotRequired)
            {
                dict = [self attributesAtIndex:i effectiveRange:&effRange];
            }
            else
            {
                dict = [self attributesAtIndex:i longestEffectiveRange:&effRange inRange:enumerationRange];
            }
            block(dict, effRange, &stop);
            if (stop)
            {
                return;
            }
            if (effRange.location == 0)
            {
                break;
            }
            previous = effRange.location - 1;
        }
        return;
    }
    NSUInteger next;
    NSUInteger limit = enumerationRange.location + enumerationRange.length;
    for (NSUInteger i = enumerationRange.location; i < limit; i = next)
    {
        NSRange effRange;
        BOOL stop = NO;
        NSDictionary *dict;
        if (opts & NSAttributedStringEnumerationLongestEffectiveRangeNotRequired)
        {
            dict = [self attributesAtIndex:i effectiveRange:&effRange];
        }
        else
        {
            dict = [self attributesAtIndex:i longestEffectiveRange:&effRange inRange:enumerationRange];
        }
        block(dict, effRange, &stop);
        if (stop)
        {
            return;
        }
        next = effRange.location + effRange.length;
    }
}

- (void)enumerateAttribute:(NSString *)attrName inRange:(NSRange)enumerationRange options:(NSAttributedStringEnumerationOptions)opts usingBlock:(void (^)(id value, NSRange range, BOOL *stop))block
{
    if ((uint64_t)enumerationRange.location + enumerationRange.length > [self length])
    {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"range (%d,%d) beyond NSAttributedString bounds (%d)", enumerationRange.location, enumerationRange.length, [self length]] userInfo:nil];
    }
    if (enumerationRange.length == 0)
    {
        return;
    }
    if (opts & NSAttributedStringEnumerationReverse)
    {
        NSUInteger previous;
        NSUInteger limit = enumerationRange.location;
        for (NSUInteger i = enumerationRange.location + enumerationRange.length - 1; i >= limit; i = previous)
        {
            NSRange effRange;
            BOOL stop = NO;
            NSDictionary *dict;
            if (opts & NSAttributedStringEnumerationLongestEffectiveRangeNotRequired)
            {
                dict = [self attributesAtIndex:i effectiveRange:&effRange];
            }
            else
            {
                dict = [self attributesAtIndex:i longestEffectiveRange:&effRange inRange:enumerationRange];
            }
            block(dict, effRange, &stop);
            if (stop)
            {
                return;
            }
            if (effRange.location == 0)
            {
                break;
            }
            previous = effRange.location - 1;
        }
        return;
    }
    NSUInteger next;
    NSUInteger limit = enumerationRange.location + enumerationRange.length;
    for (NSUInteger i = enumerationRange.location; i < limit; i = next)
    {
        NSRange effRange;
        BOOL stop = NO;
        id obj;
        if (opts & NSAttributedStringEnumerationLongestEffectiveRangeNotRequired)
        {
            obj = [self attribute:attrName atIndex:i effectiveRange:&effRange];
        }
        else
        {
            obj = [self attribute:attrName atIndex:i longestEffectiveRange:&effRange inRange:enumerationRange];
        }
        block(obj, effRange, &stop);
        if (stop)
        {
            return;
        }
        next = effRange.location + effRange.length;
    }
}

- (NSAttributedString *)copyWithZone:(NSZone *)zone
{
    // TODO optimize this to retain when input is immutable
    return [self mutableCopyWithZone:zone];
}

- (NSMutableAttributedString *)mutableCopyWithZone:(NSZone *)zone
{
    NSMutableAttributedString *retVal = [[NSMutableAttributedString alloc] initWithString:@""];
    [retVal setAttributedString:self];
    return retVal;
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit
{
    NSDictionary *retVal = [self attributesAtIndex:index effectiveRange:aRange];
    if (aRange == nil)
    {
        return retVal;
    }
    NSUInteger min = aRange->location;  // inclusive end
    NSUInteger max = aRange->location + aRange->length;  // exclusive end
    NSRange tempRange;
    while (min > 0 && [retVal isEqualToDictionary:[self attributesAtIndex:min - 1 effectiveRange:&tempRange]])
    {
        min = tempRange.location;
    }
    while (max < [self length] && [retVal isEqualToDictionary:[self attributesAtIndex:max effectiveRange:&tempRange]])
    {
        max = tempRange.location + tempRange.length;
    }
    aRange->location = min;
    aRange->length = max - min;
    *aRange = NSIntersectionRange(rangeLimit, *aRange);
    return retVal;
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit
{
    id retVal = [self attribute:attrName atIndex:index effectiveRange:aRange];
    if (aRange == nil)
    {
        return retVal;
    }
    NSUInteger min = aRange->location;  // inclusive end
    NSUInteger max = aRange->location + aRange->length;  // exclusive end
    NSRange tempRange;
    while (min > 0 && retVal == [self attribute:attrName atIndex:min - 1 effectiveRange:&tempRange])
    {
        min = tempRange.location;
    }
    while (max < [self length] && retVal == [self attribute:attrName atIndex:max effectiveRange:&tempRange])
    {
        max = tempRange.location + tempRange.length;
    }
    aRange->location = min;
    aRange->length = max - min;
    *aRange = NSIntersectionRange(rangeLimit, *aRange);
    return retVal;
}

- (Class)classForCoder
{
    return [NSAttributedString self];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    NSString *string = [self string];
    NSRange range = NSMakeRange(0, 0);
    NSDictionary *attributes = [string length] > 0 ? [self attributesAtIndex:0 effectiveRange:&range] : [NSDictionary dictionary];
    if ([string length] > 0 && range.length != [string length])
    {
        [NSException raise:NSInvalidArgumentException format:@"-[NSAttributedString encodeWithCoder:]: strings with several attribute runs are not supported"];
    }
    if ([coder allowsKeyedCoding])
    {
        [coder encodeObject:string forKey:@"NSString"];
        [coder encodeObject:attributes forKey:@"NSAttributes"];
    }
    else
    {
        [coder encodeObject:string];
        [coder encodeObject:attributes];
    }
}

- (NSUInteger)length
{
    return [[self string] length];
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
    NSDictionary *dict = [self attributesAtIndex:location effectiveRange:range];
    return [dict objectForKey:attrName];
}

- (BOOL)isEqualToAttributedString:(NSAttributedString *)other
{
    if (self == other)
    {
        return YES;
    }
    if (other == nil)
    {
        return NO;
    }
    NSUInteger len = [self length];
    if (len != [other length])
    {
        return NO;
    }
    if (![[self string] isEqualToString:[other string]])
    {
        return NO;
    }
    for (NSUInteger next, i = 0; i < len; i = next)
    {
        NSRange r1, r2;
        if (![[self attributesAtIndex:i effectiveRange:&r1] isEqualToDictionary:[other attributesAtIndex:i effectiveRange:&r2]])
        {
            return NO;
        }
        NSUInteger limit1 = r1.location + r1.length;
        NSUInteger limit2 = r2.location + r2.location;
        NSUInteger nextR = MIN(limit1, limit2);
        if (nextR > i)
        {
            next = nextR;
        }
        else
        {
            next = i + 1;
        }
    }
    return YES;
}

- (BOOL)isEqual:(id)other
{
    if (![other isKindOfClass:[NSAttributedString class]])
    {
        return NO;
    }
    return [self isEqualToAttributedString:other];
}

#warning implement NSAttributeString coding

- (NSString *)description
{
    NSMutableString *out = [[[NSMutableString alloc] init] autorelease];
    NSString *s = [self string];
    NSUInteger len = [s length];
    [self enumerateAttributesInRange:NSMakeRange(0, len) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        [out appendString:[s substringWithRange:range]];
        [out appendString:[attrs description]];
    }];
    return out;
}

- (NSUInteger)hash
{
    return [[self string] hash];
}

- (NSUInteger)_cfTypeID
{
    return CFAttributedStringGetTypeID();
}

@end

@implementation NSAttributedString (NSAttributedStringPortCoding)

- (id) replacementObjectForPortCoder: (NSPortCoder *) portCoder {
    return self;
}

@end

@implementation NSMutableAttributedString (NSMutableAttributedString)

OBJC_PROTOCOL_IMPL_PUSH
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str
{
    NSRequestConcreteImplementation();
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
    NSRequestConcreteImplementation();
}
OBJC_PROTOCOL_IMPL_POP

@end


@implementation NSMutableAttributedString (NSExtendedMutableAttributedString)

- (NSMutableString *)mutableString
{
    return [[[NSMutableStringProxyForMutableAttributedString alloc] initWithMutableAttributedString:self] autorelease];
}

- (void)addAttribute:(NSString *)name value:(id)value range:(NSRange)range
{
    NSDictionary *d = @{ name : value };
    [self addAttributes:d range:range];
}

- (void)addAttributes:(NSDictionary *)attrs range:(NSRange)range
{
    [self enumerateAttributesInRange:range options:0 usingBlock:^(NSDictionary *innerAttrs, NSRange innerRange, BOOL *stop) {
        NSMutableDictionary *d = [innerAttrs mutableCopy];
        [d addEntriesFromDictionary:attrs];
        [self setAttributes:d range:innerRange];
        [d release];
    }];
}

- (void)removeAttribute:(NSString *)name range:(NSRange)range
{
    [self enumerateAttributesInRange:range options:0 usingBlock:^(NSDictionary *attrs, NSRange innerRange, BOOL *stop) {
        NSMutableDictionary *d = [attrs mutableCopy];
        [d removeObjectForKey:name];
        [self setAttributes:d range:innerRange];
        [d release];
    }];
}

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString
{
    [self replaceCharactersInRange:range withString:[attrString string]];
    [attrString enumerateAttributesInRange:NSMakeRange(0, [attrString length]) options:0 usingBlock:^(NSDictionary *attrs, NSRange replaceRange, BOOL *stop) {
        [self setAttributes:attrs range:NSMakeRange(range.location + replaceRange.location, replaceRange.length)];
    }];
}

- (void)insertAttributedString:(NSAttributedString *)attrString atIndex:(NSUInteger)loc
{
    [self replaceCharactersInRange:NSMakeRange(loc, 0) withAttributedString:attrString];
}

- (void)appendAttributedString:(NSAttributedString *)attrString
{
    [self replaceCharactersInRange:NSMakeRange([self length], 0) withAttributedString:attrString];
}

- (void)deleteCharactersInRange:(NSRange)range
{
    [self replaceCharactersInRange:range withString:@""];
}

- (void)setAttributedString:(NSAttributedString *)attrString
{
    [self replaceCharactersInRange:NSMakeRange(0, [self length]) withAttributedString:attrString];
}

- (void)beginEditing
{
// purposeful nop
}

- (void)endEditing
{
// purposeful nop
}
@end


@implementation __NSPlaceholderAttributedString

static __NSPlaceholderAttributedString *immutablePlaceholder = nil;
static __NSPlaceholderAttributedString *mutablePlaceholder = nil;

+ (id)immutablePlaceholder
{
    static dispatch_once_t once = 0L;
    dispatch_once(&once, ^{
        immutablePlaceholder = [__NSPlaceholderAttributedString alloc];
    });
    return immutablePlaceholder;
}

+ (id)mutablePlaceholder
{
    static dispatch_once_t once = 0L;
    dispatch_once(&once, ^{
        mutablePlaceholder = [__NSPlaceholderAttributedString alloc];
    });
    return mutablePlaceholder;
}

- (id)init {
    return [self initWithString:@"" attributes:[NSDictionary dictionary]];
}

- (id)initWithString:(NSString *)str attributes:(NSDictionary *)attrs
{
    CFAttributedStringRef string = CFAttributedStringCreate(kCFAllocatorDefault, (CFStringRef)str, (CFDictionaryRef)attrs);
    _CFAttributedStringSetMutable(string, self == mutablePlaceholder);
    return (id)string;
}

// Compiled nibs archive an attributed string as its string plus one attributes dictionary
// ("NSAttributes"). Strings with several runs store an array of dictionaries and a packed
// "NSAttributeInfo" run table; that table is not decoded, so such a string takes the first
// dictionary for its whole length.
- (id)initWithCoder:(NSCoder *)coder
{
    NSString *string = nil;
    id attributes = nil;
    if ([coder allowsKeyedCoding])
    {
        string = [coder decodeObjectForKey:@"NSString"];
        attributes = [coder decodeObjectForKey:@"NSAttributes"];
    }
    else
    {
        string = [coder decodeObject];
        attributes = [coder decodeObject];
    }
    if ([attributes isKindOfClass:[NSArray class]])
    {
        attributes = [(NSArray *)attributes count] > 0 ? [(NSArray *)attributes objectAtIndex:0] : nil;
    }
    if (![attributes isKindOfClass:[NSDictionary class]])
    {
        attributes = [NSDictionary dictionary];
    }
    return [self initWithString:(string != nil ? string : @"") attributes:attributes];
}

- (id)initWithAttributedString:(NSAttributedString *)attrStr
{
    if (self == mutablePlaceholder)
    {
        return (id)CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, 0, (CFAttributedStringRef)attrStr);
    }
    else
    {
        return (id)CFAttributedStringCreateCopy(kCFAllocatorDefault, (CFAttributedStringRef)attrStr);
    }
}

SINGLETON_RR()

@end

@implementation NSMutableStringProxyForMutableAttributedString

- (id)initWithMutableAttributedString:(NSMutableAttributedString *)owner
{
    self = [super init];

    if (self)
    {
        _owner = [owner retain];
    }

    return self;
}

- (NSUInteger)length
{
    return [_owner length];
}

- (unichar)characterAtIndex:(NSUInteger)index
{
    return [[_owner string] characterAtIndex:index];
}

- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange
{
    [[_owner string] getCharacters:buffer range:aRange];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str
{
    [_owner replaceCharactersInRange:range withString:str];
}

- (void)dealloc
{
    [_owner release];
    [super dealloc];
}

@end

// The paragraph style classes live in AppKit, which Foundation cannot link
// against; they are used through the runtime when AppKit is loaded.
@protocol NSDarlingMutableParagraphStyle <NSObject>
- (void)setAlignment:(NSInteger)alignment;
- (void)setBaseWritingDirection:(NSInteger)writingDirection;
@end

static NSString * const NSDarlingParagraphStyleAttributeName = @"NSParagraphStyle";

static void NSDarlingApplyParagraphStyle(NSMutableAttributedString *attrString, NSRange range, void (^configure)(id<NSDarlingMutableParagraphStyle> style))
{
    if ((uint64_t)range.location + range.length > [attrString length])
    {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"range (%lu,%lu) beyond NSAttributedString bounds (%lu)", (unsigned long)range.location, (unsigned long)range.length, (unsigned long)[attrString length]] userInfo:nil];
    }
    Class styleClass = NSClassFromString(@"NSMutableParagraphStyle");
    if (styleClass == Nil || [attrString length] == 0)
    {
        return;
    }
    // Paragraph attributes always cover whole paragraphs.
    NSRange paragraphs = [[attrString string] paragraphRangeForRange:range];
    NSUInteger location = paragraphs.location;
    NSUInteger end = NSMaxRange(paragraphs);

    [attrString beginEditing];
    while (location < end)
    {
        NSRange effective;
        id existing = [attrString attribute:NSDarlingParagraphStyleAttributeName atIndex:location longestEffectiveRange:&effective inRange:NSMakeRange(location, end - location)];
        id<NSDarlingMutableParagraphStyle> style;
        if (existing != nil)
        {
            style = [existing mutableCopy];
        }
        else
        {
            style = [[styleClass alloc] init];
        }
        configure(style);
        [attrString addAttribute:NSDarlingParagraphStyleAttributeName value:style range:effective];
        [style release];
        location = NSMaxRange(effective);
    }
    [attrString endEditing];
}

@implementation NSMutableAttributedString (NSDarlingParagraphAttributes)

- (void)setAlignment:(NSInteger)alignment range:(NSRange)range
{
    NSDarlingApplyParagraphStyle(self, range, ^(id<NSDarlingMutableParagraphStyle> style) {
        [style setAlignment:alignment];
    });
}

- (void)setBaseWritingDirection:(NSInteger)writingDirection range:(NSRange)range
{
    NSDarlingApplyParagraphStyle(self, range, ^(id<NSDarlingMutableParagraphStyle> style) {
        [style setBaseWritingDirection:writingDirection];
    });
}

// Only plain text documents can be read without AppKit's rich text readers.
- (BOOL)readFromData:(NSData *)data options:(NSDictionary *)opts documentAttributes:(NSDictionary **)dict error:(NSError **)error
{
    NSString *documentType = [opts objectForKey:@"DocumentType"];
    if (documentType == nil)
    {
        const char *bytes = [data bytes];
        NSUInteger length = [data length];
        if (length >= 5 && strncmp(bytes, "{\\rtf", 5) == 0)
        {
            documentType = @"NSRTF";
        }
        else if (length >= 5 && (strncasecmp(bytes, "<html", 5) == 0 || strncasecmp(bytes, "<!doc", 5) == 0))
        {
            documentType = @"NSHTML";
        }
        else
        {
            documentType = @"NSPlainText";
        }
    }

    if (data == nil || ![documentType isEqual:@"NSPlainText"])
    {
        if (error != NULL)
        {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:(data == nil ? 256 : 3328) userInfo:@{
                NSLocalizedDescriptionKey: data == nil ? @"The file couldn\u2019t be opened." : @"The document type is not supported.",
            }];
        }
        return NO;
    }

    NSString *string = nil;
    NSNumber *encodingOption = [opts objectForKey:@"CharacterEncoding"];
    if (encodingOption != nil)
    {
        string = [[[NSString alloc] initWithData:data encoding:[encodingOption unsignedIntegerValue]] autorelease];
    }
    else
    {
        string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        if (string == nil)
        {
            string = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
        }
    }
    if (string == nil)
    {
        if (error != NULL)
        {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:264 userInfo:@{
                NSLocalizedDescriptionKey: @"The file couldn\u2019t be opened because the text encoding of its contents can\u2019t be determined.",
            }];
        }
        return NO;
    }

    NSDictionary *defaultAttributes = [opts objectForKey:@"DefaultAttributes"];
    NSAttributedString *loaded = [[NSAttributedString alloc] initWithString:string attributes:defaultAttributes ?: [NSDictionary dictionary]];
    [self setAttributedString:loaded];
    [loaded release];

    if (dict != NULL)
    {
        *dict = @{ @"DocumentType": @"NSPlainText" };
    }
    return YES;
}

@end
