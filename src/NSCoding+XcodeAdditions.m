#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSException.h>
#import <Foundation/NSRegularExpression.h>
#import <CoreFoundation/NSSharedKeySet.h>
#import <Foundation/NSTextCheckingResult.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSURLRequest.h>
#import <Foundation/NSURLResponse.h>
#import <Foundation/NSValue.h>

@interface NSDecimalNumberHandler (NSCodingStateAccessors)
- (NSRoundingMode)roundingMode;
- (short)scale;
- (BOOL)raiseOnExact;
- (BOOL)raiseOnOverflow;
- (BOOL)raiseOnUnderflow;
- (BOOL)raiseOnDivideByZero;
@end

static void RequireKeyedCoding(NSCoder *coder, NSString *className, NSString *selectorName)
{
    if (![coder allowsKeyedCoding])
    {
        [NSException raise:@"NSInvalidArchiveOperationException"
                    format:@"%@ %@ requires a keyed coder", className, selectorName];
    }
}

@implementation NSDecimalNumberHandler (XcodeCoding)

- (instancetype)initWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSDecimalNumberHandler", @"initWithCoder:");
    return [self initWithRoundingMode:(NSRoundingMode)[[coder decodeObjectForKey:@"roundingMode"] integerValue]
                                scale:(short)[[coder decodeObjectForKey:@"scale"] integerValue]
                     raiseOnExactness:[[coder decodeObjectForKey:@"raiseOnExactness"] boolValue]
                      raiseOnOverflow:[[coder decodeObjectForKey:@"raiseOnOverflow"] boolValue]
                     raiseOnUnderflow:[[coder decodeObjectForKey:@"raiseOnUnderflow"] boolValue]
                  raiseOnDivideByZero:[[coder decodeObjectForKey:@"raiseOnDivideByZero"] boolValue]];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSDecimalNumberHandler", @"encodeWithCoder:");
    [coder encodeObject:[NSNumber numberWithInteger:[self roundingMode]] forKey:@"roundingMode"];
    [coder encodeObject:[NSNumber numberWithShort:[self scale]] forKey:@"scale"];
    [coder encodeObject:[NSNumber numberWithBool:[self raiseOnExact]] forKey:@"raiseOnExactness"];
    [coder encodeObject:[NSNumber numberWithBool:[self raiseOnOverflow]] forKey:@"raiseOnOverflow"];
    [coder encodeObject:[NSNumber numberWithBool:[self raiseOnUnderflow]] forKey:@"raiseOnUnderflow"];
    [coder encodeObject:[NSNumber numberWithBool:[self raiseOnDivideByZero]] forKey:@"raiseOnDivideByZero"];
}

@end

@implementation NSRegularExpression (XcodeCoding)

- (instancetype)initWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSRegularExpression", @"initWithCoder:");
    NSString *pattern = [coder decodeObjectForKey:@"pattern"];
    NSRegularExpressionOptions options = (NSRegularExpressionOptions)[[coder decodeObjectForKey:@"options"] unsignedIntegerValue];
    return [self initWithPattern:pattern options:options error:NULL];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSRegularExpression", @"encodeWithCoder:");
    [coder encodeObject:[self pattern] forKey:@"pattern"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:[self options]] forKey:@"options"];
}

@end

@implementation NSSharedKeySet (XcodeCoding)

- (instancetype)initWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSSharedKeySet", @"initWithCoder:");
    NSArray *keys = [coder decodeObjectForKey:@"keys"];
    if (![keys isKindOfClass:[NSArray class]])
    {
        keys = [NSArray array];
    }

    NSUInteger count = [keys count];
    id *objects = count == 0 ? NULL : malloc(sizeof(id) * count);
    if (count != 0 && objects == NULL)
    {
        [NSException raise:NSMallocException format:@"Unable to decode NSSharedKeySet keys"];
    }
    if (count != 0)
    {
        [keys getObjects:objects range:NSMakeRange(0, count)];
    }
    self = [self initWithKeys:objects count:count];
    free(objects);
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSSharedKeySet", @"encodeWithCoder:");
    [coder encodeObject:[self allKeys] forKey:@"keys"];
}

@end

static NSRange DecodeCheckingRange(NSCoder *coder)
{
    NSValue *value = [coder decodeObjectForKey:@"range"];
    if ([value respondsToSelector:@selector(rangeValue)])
    {
        return [value rangeValue];
    }
    return NSMakeRange(NSNotFound, 0);
}

@implementation NSTextCheckingResult (XcodeCoding)

- (instancetype)initWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSTextCheckingResult", @"initWithCoder:");
    NSTextCheckingType type = (NSTextCheckingType)[[coder decodeObjectForKey:@"type"] unsignedLongLongValue];
    NSRange range = DecodeCheckingRange(coder);
    NSTextCheckingResult *result = nil;

    switch (type)
    {
        case NSTextCheckingTypeOrthography:
            result = [NSTextCheckingResult orthographyCheckingResultWithRange:range orthography:[coder decodeObjectForKey:@"orthography"]];
            break;
        case NSTextCheckingTypeSpelling:
            result = [NSTextCheckingResult spellCheckingResultWithRange:range];
            break;
        case NSTextCheckingTypeGrammar:
            result = [NSTextCheckingResult grammarCheckingResultWithRange:range details:[coder decodeObjectForKey:@"grammarDetails"]];
            break;
        case NSTextCheckingTypeDate:
            result = [NSTextCheckingResult dateCheckingResultWithRange:range
                                                                  date:[coder decodeObjectForKey:@"date"]
                                                              timeZone:[coder decodeObjectForKey:@"timeZone"]
                                                              duration:[[coder decodeObjectForKey:@"duration"] doubleValue]];
            break;
        case NSTextCheckingTypeAddress:
            result = [NSTextCheckingResult addressCheckingResultWithRange:range components:[coder decodeObjectForKey:@"components"]];
            break;
        case NSTextCheckingTypeLink:
            result = [NSTextCheckingResult linkCheckingResultWithRange:range URL:[coder decodeObjectForKey:@"URL"]];
            break;
        case NSTextCheckingTypeQuote:
            result = [NSTextCheckingResult quoteCheckingResultWithRange:range replacementString:[coder decodeObjectForKey:@"replacementString"]];
            break;
        case NSTextCheckingTypeDash:
            result = [NSTextCheckingResult dashCheckingResultWithRange:range replacementString:[coder decodeObjectForKey:@"replacementString"]];
            break;
        case NSTextCheckingTypeReplacement:
            result = [NSTextCheckingResult replacementCheckingResultWithRange:range replacementString:[coder decodeObjectForKey:@"replacementString"]];
            break;
        case NSTextCheckingTypeCorrection:
            result = [NSTextCheckingResult correctionCheckingResultWithRange:range replacementString:[coder decodeObjectForKey:@"replacementString"]];
            break;
        case NSTextCheckingTypeRegularExpression:
        {
            NSArray *encodedRanges = [coder decodeObjectForKey:@"ranges"];
            NSUInteger count = [encodedRanges count];
            if (count == 0)
            {
                count = 1;
            }
            NSRange *ranges = malloc(sizeof(NSRange) * count);
            if (ranges == NULL)
            {
                [NSException raise:NSMallocException format:@"Unable to decode regular-expression ranges"];
            }
            for (NSUInteger index = 0; index < count; ++index)
            {
                ranges[index] = index < [encodedRanges count]
                    ? [[encodedRanges objectAtIndex:index] rangeValue]
                    : range;
            }
            result = [NSTextCheckingResult regularExpressionCheckingResultWithRanges:ranges
                                                                                count:count
                                                                    regularExpression:[coder decodeObjectForKey:@"regularExpression"]];
            free(ranges);
            break;
        }
        case NSTextCheckingTypePhoneNumber:
            result = [NSTextCheckingResult phoneNumberCheckingResultWithRange:range phoneNumber:[coder decodeObjectForKey:@"phoneNumber"]];
            break;
        case NSTextCheckingTypeTransitInformation:
            result = [NSTextCheckingResult transitInformationCheckingResultWithRange:range components:[coder decodeObjectForKey:@"components"]];
            break;
        default:
            [self release];
            [NSException raise:@"NSInvalidArchiveOperationException"
                        format:@"Unsupported NSTextCheckingResult type %llu", (unsigned long long)type];
            return nil;
    }

    [self release];
    return [result retain];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSTextCheckingResult", @"encodeWithCoder:");
    [coder encodeObject:[NSNumber numberWithUnsignedLongLong:[self resultType]] forKey:@"type"];
    [coder encodeObject:[NSValue valueWithRange:[self range]] forKey:@"range"];

    switch ([self resultType])
    {
        case NSTextCheckingTypeOrthography:
            [coder encodeObject:[self orthography] forKey:@"orthography"];
            break;
        case NSTextCheckingTypeGrammar:
            [coder encodeObject:[self grammarDetails] forKey:@"grammarDetails"];
            break;
        case NSTextCheckingTypeDate:
            [coder encodeObject:[self date] forKey:@"date"];
            [coder encodeObject:[self timeZone] forKey:@"timeZone"];
            [coder encodeObject:[NSNumber numberWithDouble:[self duration]] forKey:@"duration"];
            break;
        case NSTextCheckingTypeAddress:
        case NSTextCheckingTypeTransitInformation:
            [coder encodeObject:[self components] forKey:@"components"];
            break;
        case NSTextCheckingTypeLink:
            [coder encodeObject:[self URL] forKey:@"URL"];
            break;
        case NSTextCheckingTypeQuote:
        case NSTextCheckingTypeDash:
        case NSTextCheckingTypeReplacement:
        case NSTextCheckingTypeCorrection:
            [coder encodeObject:[self replacementString] forKey:@"replacementString"];
            break;
        case NSTextCheckingTypeRegularExpression:
        {
            NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:[self numberOfRanges]];
            for (NSUInteger index = 0; index < [self numberOfRanges]; ++index)
            {
                [ranges addObject:[NSValue valueWithRange:[self rangeAtIndex:index]]];
            }
            [coder encodeObject:ranges forKey:@"ranges"];
            [coder encodeObject:[self regularExpression] forKey:@"regularExpression"];
            break;
        }
        case NSTextCheckingTypePhoneNumber:
            [coder encodeObject:[self phoneNumber] forKey:@"phoneNumber"];
            break;
        case NSTextCheckingTypeSpelling:
            break;
        default:
            [NSException raise:@"NSInvalidArchiveOperationException"
                        format:@"Unsupported NSTextCheckingResult type %llu", (unsigned long long)[self resultType]];
    }
}

@end

@implementation NSURLRequest (XcodeCoding)

- (instancetype)initWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSURLRequest", @"initWithCoder:");
    NSURL *URL = [coder decodeObjectForKey:@"URL"];
    if (URL == nil)
    {
        [self release];
        [NSException raise:@"NSInvalidArchiveOperationException" format:@"NSURLRequest archive has no URL"];
        return nil;
    }

    NSURLRequestCachePolicy policy = (NSURLRequestCachePolicy)[[coder decodeObjectForKey:@"cachePolicy"] unsignedIntegerValue];
    NSTimeInterval timeout = [[coder decodeObjectForKey:@"timeoutInterval"] doubleValue];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:policy timeoutInterval:timeout];
    [request setHTTPMethod:[coder decodeObjectForKey:@"HTTPMethod"]];
    [request setHTTPBody:[coder decodeObjectForKey:@"HTTPBody"]];
    [request setAllHTTPHeaderFields:[coder decodeObjectForKey:@"allHTTPHeaderFields"]];
    [self release];
    return (id)request;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSURLRequest", @"encodeWithCoder:");
    [coder encodeObject:[self URL] forKey:@"URL"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:[self cachePolicy]] forKey:@"cachePolicy"];
    [coder encodeObject:[NSNumber numberWithDouble:[self timeoutInterval]] forKey:@"timeoutInterval"];
    [coder encodeObject:[self HTTPMethod] forKey:@"HTTPMethod"];
    [coder encodeObject:[self HTTPBody] forKey:@"HTTPBody"];
    [coder encodeObject:[self allHTTPHeaderFields] forKey:@"allHTTPHeaderFields"];
}

@end

@implementation NSURLResponse (XcodeCoding)

- (instancetype)initWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSURLResponse", @"initWithCoder:");
    NSURL *URL = [coder decodeObjectForKey:@"URL"];
    NSString *MIMEType = [coder decodeObjectForKey:@"MIMEType"];
    NSInteger length = (NSInteger)[[coder decodeObjectForKey:@"expectedContentLength"] longLongValue];
    NSString *encoding = [coder decodeObjectForKey:@"textEncodingName"];
    return [self initWithURL:URL MIMEType:MIMEType expectedContentLength:length textEncodingName:encoding];
}

@end

@implementation NSURLQueryItem (XcodeCoding)

- (instancetype)initWithCoder:(NSCoder *)coder
{
    RequireKeyedCoding(coder, @"NSURLQueryItem", @"initWithCoder:");
    NSString *name = [coder decodeObjectForKey:@"name"];
    NSString *value = [coder decodeObjectForKey:@"value"];
    return [self initWithName:name value:value];
}

@end
