//
//  NSTextCheckingResult.m
//  Foundation
//
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "NSTransitInformationCheckingResult.h"
#import "NSPhoneNumberCheckingResult.h"
#import "NSRegularExpressionCheckingResult.h"
#import "NSSubstitutionCheckingResult.h"
#import "NSLinkCheckingResult.h"
#import "NSDateCheckingResult.h"
#import "NSGrammarCheckingResult.h"
#import "NSSpellCheckingResult.h"
#import "NSOrthographyCheckingResult.h"
#import "NSAddressCheckingResult.h"
#import <Foundation/NSException.h>
#import <objc/runtime.h>

NSString * const NSTextCheckingNameKey = @"Name";
NSString * const NSTextCheckingJobTitleKey = @"JobTitle";
NSString * const NSTextCheckingOrganizationKey = @"Organization";
NSString * const NSTextCheckingStreetKey = @"Street";
NSString * const NSTextCheckingCityKey = @"City";
NSString * const NSTextCheckingStateKey = @"State";
NSString * const NSTextCheckingZIPKey = @"ZIP";
NSString * const NSTextCheckingCountryKey = @"Country";
NSString * const NSTextCheckingPhoneKey = @"Phone";
NSString * const NSTextCheckingAirlineKey = @"Airline";
NSString * const NSTextCheckingFlightKey = @"Flight";

static NSRange NSTextCheckingRangeByAddingOffset(NSRange range, NSInteger offset)
{
    if (range.location == NSNotFound || offset == 0)
        return range;

    if (offset < 0) {
        NSUInteger magnitude = (NSUInteger)(-(offset + 1)) + 1;
        if (range.location < magnitude)
            [NSException raise:NSRangeException format:@"Range offset moves the range before index zero"];
        range.location -= magnitude;
    } else {
        NSUInteger magnitude = (NSUInteger)offset;
        if (range.location > NSUIntegerMax - magnitude)
            [NSException raise:NSRangeException format:@"Range offset overflows the range location"];
        range.location += magnitude;
    }
    return range;
}

@interface _NSTextCheckingResultWithRangeOffset : NSTextCheckingResult {
    NSTextCheckingResult *_originalResult;
    NSInteger _rangeOffset;
}
- (id)initWithResult:(NSTextCheckingResult *)result offset:(NSInteger)offset;
@end

@implementation _NSTextCheckingResultWithRangeOffset
- (id)initWithResult:(NSTextCheckingResult *)result offset:(NSInteger)offset
{
    self = [super init];
    if (self) {
        _originalResult = [result retain];
        _rangeOffset = offset;
    }
    return self;
}

- (void)dealloc
{
    [_originalResult release];
    [super dealloc];
}

- (NSTextCheckingType)resultType
{
    return [_originalResult resultType];
}

- (NSRange)range
{
    return [self rangeAtIndex:0];
}

- (NSUInteger)numberOfRanges
{
    return [_originalResult numberOfRanges];
}

- (NSRange)rangeAtIndex:(NSUInteger)index
{
    if (index >= [self numberOfRanges])
        [NSException raise:NSRangeException format:@"Range index %lu is out of bounds", (unsigned long)index];
    return NSTextCheckingRangeByAddingOffset([_originalResult rangeAtIndex:index], _rangeOffset);
}

- (NSTextCheckingResult *)resultByAdjustingRangesWithOffset:(NSInteger)offset
{
    if (offset == 0)
        return [[self retain] autorelease];
    for (NSUInteger index = 0; index < [self numberOfRanges]; ++index)
        NSTextCheckingRangeByAddingOffset([self rangeAtIndex:index], offset);
    return [[[[self class] alloc] initWithResult:self offset:offset] autorelease];
}

- (NSURL *)URL { return [_originalResult URL]; }
- (NSDictionary *)components { return [_originalResult components]; }
- (NSDate *)date { return [_originalResult date]; }
- (NSTimeInterval)duration { return [_originalResult duration]; }
- (NSRegularExpression *)regularExpression { return [_originalResult regularExpression]; }
- (NSString *)replacementString { return [_originalResult replacementString]; }
- (NSTimeZone *)timeZone { return [_originalResult timeZone]; }
@end

@implementation NSTextCheckingResult

+ (void)initialize
{

}

- (NSURL *)URL
{
    return nil;
}

- (NSDictionary *)components
{
    return nil;
}

- (NSDate *)date
{
    return nil;
}

- (NSTimeInterval)duration
{
    Ivar ivar = class_getInstanceVariable([self class], "_duration");
    if (ivar == NULL)
        return 0.0;
    return *(NSTimeInterval *)((char *)(void *)self + ivar_getOffset(ivar));
}

- (NSUInteger)numberOfRanges
{
    return 1;
}

- (NSRange)rangeAtIndex:(NSUInteger)index
{
    if (index != 0)
        [NSException raise:NSRangeException format:@"Range index %lu is out of bounds", (unsigned long)index];
    return [self range];
}

- (NSRegularExpression *)regularExpression
{
    return nil;
}

- (NSString *)replacementString
{
    return nil;
}

- (NSTextCheckingResult *)resultByAdjustingRangesWithOffset:(NSInteger)offset
{
    for (NSUInteger index = 0; index < [self numberOfRanges]; ++index)
        NSTextCheckingRangeByAddingOffset([self rangeAtIndex:index], offset);
    return [[[_NSTextCheckingResultWithRangeOffset alloc] initWithResult:self offset:offset] autorelease];
}

- (NSTimeZone *)timeZone
{
    Ivar ivar = class_getInstanceVariable([self class], "_timeZone");
    if (ivar == NULL)
        return nil;
    void *value = NULL;
    object_getInstanceVariable(self, "_timeZone", &value);
    return (NSTimeZone *)value;
}

+ (NSTextCheckingResult *)transitInformationCheckingResultWithRange:(NSRange)range components:(NSDictionary *)components
{
    return [[[NSTransitInformationCheckingResult alloc] initWithRange:range components:components] autorelease];
}

+ (NSTextCheckingResult *)phoneNumberCheckingResultWithRange:(NSRange)range phoneNumber:(NSString *)phoneNumber
{
    return [[[NSPhoneNumberCheckingResult alloc] initWithRange:range phoneNumber:phoneNumber] autorelease];
}

+ (NSTextCheckingResult *)regularExpressionCheckingResultWithRanges:(NSRangePointer)ranges count:(NSUInteger)count regularExpression:(NSRegularExpression *)regularExpression
{
    if (count <= 3)
    {
        return [[[NSSimpleRegularExpressionCheckingResult alloc] initWithRanges:ranges count:count regularExpression:regularExpression] autorelease];    
    }
    else if (count <= 7)
    {
        return [[[NSExtendedRegularExpressionCheckingResult alloc] initWithRanges:ranges count:count regularExpression:regularExpression] autorelease];    
    }
    else
    {
        return [[[NSComplexRegularExpressionCheckingResult alloc] initWithRanges:ranges count:count regularExpression:regularExpression] autorelease];       
    }
}

+ (NSTextCheckingResult *)correctionCheckingResultWithRange:(NSRange)range replacementString:(NSString *)replacementString
{
    return [[[NSCorrectionCheckingResult alloc] initWithRange:range replacementString:replacementString] autorelease];
}

+ (NSTextCheckingResult *)replacementCheckingResultWithRange:(NSRange)range replacementString:(NSString *)replacementString
{
    return [[[NSSubstitutionCheckingResult alloc] initWithRange:range replacementString:replacementString] autorelease];
}

+ (NSTextCheckingResult *)dashCheckingResultWithRange:(NSRange)range replacementString:(NSString *)replacementString
{
    return [[[NSDashCheckingResult alloc] initWithRange:range replacementString:replacementString] autorelease];
}

+ (NSTextCheckingResult *)quoteCheckingResultWithRange:(NSRange)range replacementString:(NSString *)replacementString
{
    return [[[NSQuoteCheckingResult alloc] initWithRange:range replacementString:replacementString] autorelease];
}

+ (NSTextCheckingResult *)linkCheckingResultWithRange:(NSRange)range URL:(NSURL *)url
{
    return [[[NSLinkCheckingResult alloc] initWithRange:range URL:url] autorelease];
}

+ (NSTextCheckingResult *)addressCheckingResultWithRange:(NSRange)range components:(NSDictionary *)components
{
    return [[[NSAddressCheckingResult alloc] initWithRange:range components:components] autorelease];
}

+ (NSTextCheckingResult *)dateCheckingResultWithRange:(NSRange)range date:(NSDate *)date timeZone:(NSTimeZone *)timeZone duration:(NSTimeInterval)duration
{
    return [[[NSDateCheckingResult alloc] initWithRange:range date:date timeZone:timeZone duration:duration] autorelease];
}

+ (NSTextCheckingResult *)dateCheckingResultWithRange:(NSRange)range date:(NSDate *)date
{
    return [[[NSDateCheckingResult alloc] initWithRange:range date:date] autorelease];   
}

+ (NSTextCheckingResult *)grammarCheckingResultWithRange:(NSRange)range details:(NSArray *)details
{
    return [[[NSGrammarCheckingResult alloc] initWithRange:range details:details] autorelease];
}

+ (NSTextCheckingResult *)spellCheckingResultWithRange:(NSRange)range
{
    return [[[NSSpellCheckingResult alloc] initWithRange:range] autorelease];
}

+ (NSTextCheckingResult *)orthographyCheckingResultWithRange:(NSRange)range orthography:(NSOrthography *)orthography
{
    return [[[NSOrthographyCheckingResult alloc] initWithRange:range orthography:orthography] autorelease];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}


@end

@implementation NSAddressCheckingResult (NSTextCheckingResultRangeAdjustment)

/* NSAddressCheckingResult's legacy implementation only logged and returned nil. */
- (NSTextCheckingResult *)resultByAdjustingRangesWithOffset:(NSInteger)offset
{
    for (NSUInteger index = 0; index < [self numberOfRanges]; ++index)
        NSTextCheckingRangeByAddingOffset([self rangeAtIndex:index], offset);
    return [[[_NSTextCheckingResultWithRangeOffset alloc] initWithResult:self offset:offset] autorelease];
}

@end

