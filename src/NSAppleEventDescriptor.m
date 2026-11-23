/*
 This file is part of Darling.

 Copyright (C) 2025 Darling Developers

 Darling is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Darling is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Darling.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <Foundation/NSAppleEventDescriptor.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSValue.h>
#include <string.h>

/*
 * Descriptors are kept as plain Objective-C state: a type code plus either a
 * block of data (scalars) or an ordered list of (keyword, descriptor) pairs
 * (lists, records and events).  Apple events additionally carry attributes.
 */

#define AED_FOURCC(a, b, c, d) \
    (((UInt32)(a) << 24) | ((UInt32)(b) << 16) | ((UInt32)(c) << 8) | (UInt32)(d))

enum {
    kAEDTypeNull = AED_FOURCC('n', 'u', 'l', 'l'),
    kAEDTypeBoolean = AED_FOURCC('b', 'o', 'o', 'l'),
    kAEDTypeTrue = AED_FOURCC('t', 'r', 'u', 'e'),
    kAEDTypeFalse = AED_FOURCC('f', 'a', 'l', 's'),
    kAEDTypeSInt16 = AED_FOURCC('s', 'h', 'o', 'r'),
    kAEDTypeSInt32 = AED_FOURCC('l', 'o', 'n', 'g'),
    kAEDTypeIEEE64 = AED_FOURCC('d', 'o', 'u', 'b'),
    kAEDTypeUnicodeText = AED_FOURCC('u', 't', 'x', 't'),
    kAEDTypeUTF8Text = AED_FOURCC('u', 't', 'f', '8'),
    kAEDTypeChar = AED_FOURCC('T', 'E', 'X', 'T'),
    kAEDTypeEnumerated = AED_FOURCC('e', 'n', 'u', 'm'),
    kAEDTypeType = AED_FOURCC('t', 'y', 'p', 'e'),
    kAEDTypeAEList = AED_FOURCC('l', 'i', 's', 't'),
    kAEDTypeAERecord = AED_FOURCC('r', 'e', 'c', 'o'),
    kAEDTypeAppleEvent = AED_FOURCC('a', 'e', 'v', 't'),
    kAEDTypeLongDateTime = AED_FOURCC('l', 'd', 't', ' '),
    kAEDKeyEventClass = AED_FOURCC('e', 'v', 'c', 'l'),
    kAEDKeyEventID = AED_FOURCC('e', 'v', 'i', 'd'),
    kAEDKeyReturnID = AED_FOURCC('r', 't', 'i', 'd'),
    kAEDKeyTransactionID = AED_FOURCC('t', 'r', 'a', 'n')
};

/* Seconds between the AppleEvent epoch (1904-01-01) and the Unix epoch. */
static const double AEDEpochOffset = 2082844800.0;

static int AEDNextReturnID = 1;

@implementation NSAppleEventDescriptor

#pragma mark - Construction

- (id)initWithAEDescNoCopy:(const struct AEDesc *)aeDesc
{
    if ((self = [super init]) != nil) {
        /* The AE handle storage is not available; only the type is carried over. */
        _aedType = (aeDesc != NULL) ? aeDesc->descriptorType : kAEDTypeNull;
        _aedData = [[NSData alloc] init];
    }
    return self;
}

- (id)init
{
    return [self initWithAEDescNoCopy: NULL];
}

- (id)initWithDescriptorType:(DescType)descriptorType
                       bytes:(const void *)bytes
                      length:(NSUInteger)byteCount
{
    if ((self = [self initWithAEDescNoCopy: NULL]) != nil) {
        _aedType = descriptorType;
        [_aedData release];
        _aedData = [[NSData alloc] initWithBytes: bytes length: (bytes != NULL) ? byteCount : 0];
        if (descriptorType == kAEDTypeAEList || descriptorType == kAEDTypeAERecord ||
            descriptorType == kAEDTypeAppleEvent) {
            _aedItems = [[NSMutableArray alloc] init];
            _aedKeys = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

- (id)initWithDescriptorType:(DescType)descriptorType data:(NSData *)data
{
    return [self initWithDescriptorType: descriptorType
                                  bytes: [data bytes]
                                 length: [data length]];
}

- (id)initListDescriptor
{
    return [self initWithDescriptorType: kAEDTypeAEList bytes: NULL length: 0];
}

- (id)initRecordDescriptor
{
    return [self initWithDescriptorType: kAEDTypeAERecord bytes: NULL length: 0];
}

- (id)initWithEventClass:(AEEventClass)eventClass
                 eventID:(AEEventID)eventID
        targetDescriptor:(NSAppleEventDescriptor *)addressDescriptor
                returnID:(AEReturnID)returnID
           transactionID:(AETransactionID)transactionID
{
    if ((self = [self initWithDescriptorType: kAEDTypeAppleEvent bytes: NULL length: 0]) != nil) {
        _aedEventClass = eventClass;
        _aedEventID = eventID;
        if (returnID == -1) {
            @synchronized([NSAppleEventDescriptor class]) {
                AEDNextReturnID = (AEDNextReturnID >= 32767) ? 1 : AEDNextReturnID + 1;
                returnID = (AEReturnID) AEDNextReturnID;
            }
        }
        _aedReturnID = returnID;
        _aedTransactionID = transactionID;
        _aedAttributes = [[NSMutableDictionary alloc] init];
        if (addressDescriptor != nil)
            [_aedAttributes setObject: addressDescriptor
                               forKey: [NSNumber numberWithUnsignedInt: AED_FOURCC('a', 'd', 'd', 'r')]];
    }
    return self;
}

- (void)dealloc
{
    [_aedData release];
    [_aedItems release];
    [_aedKeys release];
    [_aedAttributes release];
    [super dealloc];
}

+ (NSAppleEventDescriptor *)appleEventWithEventClass:(AEEventClass)eventClass
                                             eventID:(AEEventID)eventID
                                    targetDescriptor:(NSAppleEventDescriptor *)addressDescriptor
                                            returnID:(AEReturnID)returnID
                                       transactionID:(AETransactionID)transactionID
{
    return [[[self alloc] initWithEventClass: eventClass
                                     eventID: eventID
                            targetDescriptor: addressDescriptor
                                    returnID: returnID
                               transactionID: transactionID] autorelease];
}

+ (NSAppleEventDescriptor *)nullDescriptor
{
    return [[[self alloc] initWithDescriptorType: kAEDTypeNull bytes: NULL length: 0] autorelease];
}

+ (NSAppleEventDescriptor *)descriptorWithDescriptorType:(DescType)descriptorType
                                                   bytes:(const void *)bytes
                                                  length:(NSUInteger)byteCount
{
    return [[[self alloc] initWithDescriptorType: descriptorType
                                           bytes: bytes
                                          length: byteCount] autorelease];
}

+ (NSAppleEventDescriptor *)descriptorWithDescriptorType:(DescType)descriptorType
                                                    data:(NSData *)data
{
    return [[[self alloc] initWithDescriptorType: descriptorType data: data] autorelease];
}

+ (NSAppleEventDescriptor *)descriptorWithBoolean:(Boolean)boolean
{
    UInt8 value = boolean ? 1 : 0;
    return [self descriptorWithDescriptorType: kAEDTypeBoolean bytes: &value length: sizeof(value)];
}

+ (NSAppleEventDescriptor *)descriptorWithEnumCode:(OSType)enumerator
{
    return [self descriptorWithDescriptorType: kAEDTypeEnumerated
                                        bytes: &enumerator
                                       length: sizeof(enumerator)];
}

+ (NSAppleEventDescriptor *)descriptorWithInt32:(SInt32)signedInt
{
    return [self descriptorWithDescriptorType: kAEDTypeSInt32
                                        bytes: &signedInt
                                       length: sizeof(signedInt)];
}

+ (NSAppleEventDescriptor *)descriptorWithDouble:(double)doubleValue
{
    return [self descriptorWithDescriptorType: kAEDTypeIEEE64
                                        bytes: &doubleValue
                                       length: sizeof(doubleValue)];
}

+ (NSAppleEventDescriptor *)descriptorWithTypeCode:(OSType)typeCode
{
    return [self descriptorWithDescriptorType: kAEDTypeType
                                        bytes: &typeCode
                                       length: sizeof(typeCode)];
}

+ (NSAppleEventDescriptor *)descriptorWithString:(NSString *)string
{
    NSData *data = [string dataUsingEncoding: NSUTF16LittleEndianStringEncoding];
    return [self descriptorWithDescriptorType: kAEDTypeUnicodeText data: data];
}

+ (NSAppleEventDescriptor *)descriptorWithDate:(NSDate *)date
{
    SInt64 seconds = (SInt64)([date timeIntervalSince1970] + AEDEpochOffset +
                              [[NSTimeZone localTimeZone] secondsFromGMTForDate: date]);
    return [self descriptorWithDescriptorType: kAEDTypeLongDateTime
                                        bytes: &seconds
                                       length: sizeof(seconds)];
}

+ (NSAppleEventDescriptor *)listDescriptor
{
    return [[[self alloc] initListDescriptor] autorelease];
}

+ (NSAppleEventDescriptor *)recordDescriptor
{
    return [[[self alloc] initRecordDescriptor] autorelease];
}

#pragma mark - Basic accessors

- (const struct AEDesc *)aeDesc
{
    _aedStruct.descriptorType = _aedType;
    _aedStruct.dataHandle = NULL;
    return &_aedStruct;
}

- (DescType)descriptorType
{
    return _aedType;
}

- (NSData *)data
{
    return _aedData != nil ? _aedData : [NSData data];
}

- (BOOL)isContainer
{
    return _aedItems != nil;
}

- (OSType)enumCodeValue
{
    return [self _fourCharValue];
}

- (OSType)typeCodeValue
{
    return [self _fourCharValue];
}

- (OSType)_fourCharValue
{
    OSType value = 0;

    if (_aedType == kAEDTypeEnumerated || _aedType == kAEDTypeType) {
        if ([_aedData length] >= sizeof(value))
            memcpy(&value, [_aedData bytes], sizeof(value));
        return value;
    }
    if ((_aedType == kAEDTypeChar || _aedType == kAEDTypeUTF8Text ||
         _aedType == kAEDTypeUnicodeText) && [[self stringValue] length] == 4) {
        const char *text = [[self stringValue] UTF8String];
        return AED_FOURCC(text[0], text[1], text[2], text[3]);
    }
    return 0;
}

- (AEEventClass)eventClass
{
    return _aedEventClass;
}

- (AEEventID)eventID
{
    return _aedEventID;
}

- (AEReturnID)returnID
{
    return _aedReturnID;
}

- (AETransactionID)transactionID
{
    return _aedTransactionID;
}

#pragma mark - Value coercion

/* Interprets the descriptor as a number; returns NO when it is not numeric. */
- (BOOL)_numberValue:(double *)result
{
    const void *bytes = [_aedData bytes];
    NSUInteger length = [_aedData length];

    switch (_aedType) {
    case kAEDTypeBoolean:
        *result = (length >= 1 && ((const UInt8 *) bytes)[0] != 0) ? 1 : 0;
        return YES;
    case kAEDTypeTrue:
        *result = 1;
        return YES;
    case kAEDTypeFalse:
        *result = 0;
        return YES;
    case kAEDTypeSInt16: {
        SInt16 v = 0;
        if (length >= sizeof(v))
            memcpy(&v, bytes, sizeof(v));
        *result = v;
        return YES;
    }
    case kAEDTypeSInt32: {
        SInt32 v = 0;
        if (length >= sizeof(v))
            memcpy(&v, bytes, sizeof(v));
        *result = v;
        return YES;
    }
    case kAEDTypeIEEE64: {
        double v = 0;
        if (length >= sizeof(v))
            memcpy(&v, bytes, sizeof(v));
        *result = v;
        return YES;
    }
    case kAEDTypeUnicodeText:
    case kAEDTypeUTF8Text:
    case kAEDTypeChar: {
        NSString *text = [self stringValue];
        if (text == nil)
            return NO;
        if ([text caseInsensitiveCompare: @"true"] == NSOrderedSame) {
            *result = 1;
            return YES;
        }
        if ([text caseInsensitiveCompare: @"false"] == NSOrderedSame) {
            *result = 0;
            return YES;
        }
        *result = [text doubleValue];
        return YES;
    }
    default:
        return NO;
    }
}

- (Boolean)booleanValue
{
    double value = 0;
    return [self _numberValue: &value] && value != 0;
}

- (SInt32)int32Value
{
    double value = 0;
    if (![self _numberValue: &value])
        return 0;
    if (value > 2147483647.0)
        return 2147483647;
    if (value < -2147483648.0)
        return (SInt32) -2147483648LL;
    return (SInt32) value;
}

- (double)doubleValue
{
    double value = 0;
    return [self _numberValue: &value] ? value : 0;
}

- (NSString *)stringValue
{
    const void *bytes = [_aedData bytes];
    NSUInteger length = [_aedData length];

    switch (_aedType) {
    case kAEDTypeUnicodeText:
        return [[[NSString alloc] initWithBytes: bytes
                                         length: length
                                       encoding: NSUTF16LittleEndianStringEncoding] autorelease];
    case kAEDTypeUTF8Text:
    case kAEDTypeChar:
        return [[[NSString alloc] initWithBytes: bytes
                                         length: length
                                       encoding: NSUTF8StringEncoding] autorelease];
    case kAEDTypeBoolean:
    case kAEDTypeTrue:
    case kAEDTypeFalse:
        return [self booleanValue] ? @"true" : @"false";
    case kAEDTypeSInt16:
    case kAEDTypeSInt32:
        return [NSString stringWithFormat: @"%d", (int) [self int32Value]];
    case kAEDTypeIEEE64:
        return [NSString stringWithFormat: @"%g", [self doubleValue]];
    case kAEDTypeEnumerated:
    case kAEDTypeType: {
        OSType code = [self _fourCharValue];
        char text[5] = {(char)(code >> 24), (char)(code >> 16), (char)(code >> 8), (char) code, 0};
        return [NSString stringWithCString: text encoding: NSMacOSRomanStringEncoding];
    }
    default:
        return nil;
    }
}

- (NSDate *)dateValue
{
    SInt64 seconds = 0;

    if (_aedType != kAEDTypeLongDateTime || [_aedData length] < sizeof(seconds))
        return nil;
    memcpy(&seconds, [_aedData bytes], sizeof(seconds));

    NSDate *guess = [NSDate dateWithTimeIntervalSince1970: (double) seconds - AEDEpochOffset];
    return [guess dateByAddingTimeInterval: -[[NSTimeZone localTimeZone] secondsFromGMTForDate: guess]];
}

- (NSAppleEventDescriptor *)coerceToDescriptorType:(DescType)descriptorType
{
    if (descriptorType == _aedType)
        return self;

    switch (descriptorType) {
    case kAEDTypeUnicodeText:
    case kAEDTypeUTF8Text:
    case kAEDTypeChar: {
        NSString *text = [self stringValue];
        if (text == nil)
            return nil;
        NSStringEncoding encoding = (descriptorType == kAEDTypeUnicodeText)
                                            ? NSUTF16LittleEndianStringEncoding
                                            : NSUTF8StringEncoding;
        return [NSAppleEventDescriptor descriptorWithDescriptorType: descriptorType
                                                               data: [text dataUsingEncoding: encoding]];
    }
    case kAEDTypeBoolean: {
        double value;
        if (![self _numberValue: &value])
            return nil;
        return [NSAppleEventDescriptor descriptorWithBoolean: value != 0];
    }
    case kAEDTypeSInt16: {
        double value;
        if (![self _numberValue: &value])
            return nil;
        SInt16 small = (SInt16) [self int32Value];
        return [NSAppleEventDescriptor descriptorWithDescriptorType: descriptorType
                                                              bytes: &small
                                                             length: sizeof(small)];
    }
    case kAEDTypeSInt32: {
        double value;
        if (![self _numberValue: &value])
            return nil;
        return [NSAppleEventDescriptor descriptorWithInt32: [self int32Value]];
    }
    case kAEDTypeIEEE64: {
        double value;
        if (![self _numberValue: &value])
            return nil;
        return [NSAppleEventDescriptor descriptorWithDouble: value];
    }
    case kAEDTypeEnumerated:
    case kAEDTypeType: {
        if (_aedType != kAEDTypeEnumerated && _aedType != kAEDTypeType && [[self stringValue] length] != 4)
            return nil;
        OSType code = [self _fourCharValue];
        return [NSAppleEventDescriptor descriptorWithDescriptorType: descriptorType
                                                              bytes: &code
                                                             length: sizeof(code)];
    }
    case kAEDTypeLongDateTime:
        return nil;
    case kAEDTypeAEList: {
        NSAppleEventDescriptor *list = [NSAppleEventDescriptor listDescriptor];
        [list insertDescriptor: self atIndex: 0];
        return list;
    }
    default:
        /* Unknown target types keep the raw data, as AECoerceDesc does for data-compatible types. */
        if (_aedItems == nil)
            return [NSAppleEventDescriptor descriptorWithDescriptorType: descriptorType data: _aedData];
        return nil;
    }
}

#pragma mark - Lists and records

- (NSInteger)numberOfItems
{
    return (NSInteger) [_aedItems count];
}

- (void)insertDescriptor:(NSAppleEventDescriptor *)descriptor atIndex:(NSInteger)anIndex
{
    if (_aedItems == nil || descriptor == nil)
        return;
    NSInteger count = (NSInteger) [_aedItems count];
    NSInteger position = (anIndex <= 0 || anIndex > count) ? count : anIndex - 1;

    [_aedItems insertObject: descriptor atIndex: position];
    [_aedKeys insertObject: [NSNumber numberWithUnsignedInt: 0] atIndex: position];
}

- (NSAppleEventDescriptor *)descriptorAtIndex:(NSInteger)anIndex
{
    if (anIndex < 1 || anIndex > (NSInteger) [_aedItems count])
        return nil;
    return [_aedItems objectAtIndex: anIndex - 1];
}

- (void)removeDescriptorAtIndex:(NSInteger)anIndex
{
    if (anIndex < 1 || anIndex > (NSInteger) [_aedItems count])
        return;
    [_aedItems removeObjectAtIndex: anIndex - 1];
    [_aedKeys removeObjectAtIndex: anIndex - 1];
}

- (NSInteger)_indexForKeyword:(AEKeyword)keyword
{
    NSNumber *key = [NSNumber numberWithUnsignedInt: keyword];
    NSUInteger i, count = [_aedKeys count];

    for (i = 0; i < count; i++)
        if ([[_aedKeys objectAtIndex: i] isEqual: key])
            return (NSInteger) i;
    return -1;
}

- (void)setDescriptor:(NSAppleEventDescriptor *)descriptor forKeyword:(AEKeyword)keyword
{
    if (_aedItems == nil || _aedType == kAEDTypeAEList || descriptor == nil)
        return;
    NSInteger index = [self _indexForKeyword: keyword];

    if (index >= 0) {
        [_aedItems replaceObjectAtIndex: index withObject: descriptor];
    } else {
        [_aedItems addObject: descriptor];
        [_aedKeys addObject: [NSNumber numberWithUnsignedInt: keyword]];
    }
}

- (NSAppleEventDescriptor *)descriptorForKeyword:(AEKeyword)keyword
{
    NSInteger index = [self _indexForKeyword: keyword];
    return (index >= 0 && _aedType != kAEDTypeAEList) ? [_aedItems objectAtIndex: index] : nil;
}

- (void)removeDescriptorWithKeyword:(AEKeyword)keyword
{
    NSInteger index = [self _indexForKeyword: keyword];

    if (index >= 0 && _aedType != kAEDTypeAEList) {
        [_aedItems removeObjectAtIndex: index];
        [_aedKeys removeObjectAtIndex: index];
    }
}

- (AEKeyword)keywordForDescriptorAtIndex:(NSInteger)anIndex
{
    if (_aedType == kAEDTypeAEList || anIndex < 1 || anIndex > (NSInteger) [_aedKeys count])
        return 0;
    return (AEKeyword)[[_aedKeys objectAtIndex: anIndex - 1] unsignedIntValue];
}

#pragma mark - Apple event parameters and attributes

- (void)setParamDescriptor:(NSAppleEventDescriptor *)descriptor forKeyword:(AEKeyword)keyword
{
    [self setDescriptor: descriptor forKeyword: keyword];
}

- (NSAppleEventDescriptor *)paramDescriptorForKeyword:(AEKeyword)keyword
{
    return [self descriptorForKeyword: keyword];
}

- (void)removeParamDescriptorWithKeyword:(AEKeyword)keyword
{
    [self removeDescriptorWithKeyword: keyword];
}

- (void)setAttributeDescriptor:(NSAppleEventDescriptor *)descriptor forKeyword:(AEKeyword)keyword
{
    if (_aedAttributes == nil || descriptor == nil)
        return;
    [_aedAttributes setObject: descriptor forKey: [NSNumber numberWithUnsignedInt: keyword]];
}

- (NSAppleEventDescriptor *)attributeDescriptorForKeyword:(AEKeyword)keyword
{
    if (_aedAttributes == nil)
        return nil;

    switch (keyword) {
    case kAEDKeyEventClass:
        return [NSAppleEventDescriptor descriptorWithTypeCode: _aedEventClass];
    case kAEDKeyEventID:
        return [NSAppleEventDescriptor descriptorWithTypeCode: _aedEventID];
    case kAEDKeyReturnID: {
        SInt16 value = _aedReturnID;
        return [NSAppleEventDescriptor descriptorWithDescriptorType: kAEDTypeSInt16
                                                              bytes: &value
                                                             length: sizeof(value)];
    }
    case kAEDKeyTransactionID:
        return [NSAppleEventDescriptor descriptorWithInt32: _aedTransactionID];
    default:
        return [_aedAttributes objectForKey: [NSNumber numberWithUnsignedInt: keyword]];
    }
}

@end
