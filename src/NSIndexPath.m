//
//  NSIndexPath.m
//  Foundation
//
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/NSIndexPath.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSException.h>
#import <string.h>
#import <stdlib.h>

@implementation NSIndexPath

+ (id)indexPathWithIndex:(NSUInteger)index
{
    return [[[self alloc] initWithIndex:index] autorelease];
}

+ (id)indexPathForItem:(NSInteger)item inSection:(NSInteger)section
{
    NSUInteger indexes[2] = { (NSUInteger)section, (NSUInteger)item };
    return [[[self alloc] initWithIndexes:indexes length:2] autorelease];
}

+ (id)indexPathWithIndexes:(const NSUInteger [])indexes length:(NSUInteger)length
{
    return [[[self alloc] initWithIndexes:indexes length:length] autorelease];
}

- (id)initWithIndex:(NSUInteger)index
{
    return [self initWithIndexes:&index length:1];
}

- (id)initWithIndexes:(const NSUInteger [])indexes length:(NSUInteger)length
{
    self = [super init];
    if (self)
    {
        _length = length;
        if (length > 0)
        {
            _indexes = malloc(sizeof(NSUInteger) * length);
            memcpy(_indexes, indexes, sizeof(NSUInteger) * length);
        }
    }
    return self;
}

- (id)_initWithIndexesNoCopy:(NSUInteger *)indexes length:(NSUInteger)length
{
    self = [super init];
    if (self)
    {
        _indexes = indexes;
        _length = length;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
#warning TODO: FIXME
    [self release];
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
#warning TODO: FIXME
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (void)dealloc
{
    if (_indexes != NULL) {
        free(_indexes);
    }
    [super dealloc];
}

- (NSUInteger)hash
{
    if (_hash == 0)
    {
        NSUInteger length = [self length];
        _hash = length;
        if (length > 0)
        {
            _hash += [self indexAtPosition:0];
            _hash += [self indexAtPosition:length - 1];
        }
    }
    
    return _hash;
}

- (BOOL)isEqual:(id)other
{
    BOOL isEqual = NO;
    if (other == self) 
    {
        isEqual = YES;
    } 
    else if ([other isKindOfClass:[NSIndexPath class]])
    {
        isEqual = [self compare:other] == NSOrderedSame;
    }

    return isEqual;
}

- (NSIndexPath *)indexPathByAddingIndex:(NSUInteger)index
{
    NSUInteger *indexes = malloc(sizeof(NSUInteger) * (_length + 1));
    if (_length > 0)
    {
        memcpy(indexes, _indexes, sizeof(NSUInteger) * _length);
    }
    indexes[_length] = index;
    return [[[NSIndexPath alloc] _initWithIndexesNoCopy:indexes length:_length + 1] autorelease];
}

- (NSIndexPath *)indexPathByRemovingLastIndex
{
    if (_length > 0)
    {
        return [[[NSIndexPath alloc] initWithIndexes:_indexes length:_length - 1] autorelease];
    }
    else
    {
        return [[[NSIndexPath alloc] initWithIndexes:NULL length:0] autorelease];
    }
}

- (NSUInteger)indexAtPosition:(NSUInteger)position
{
    if (position >= _length)
    {
        return NSNotFound;
    }
    return _indexes[position];
}

- (NSUInteger)length
{
    return _length;
}

- (void)getIndexes:(NSUInteger *)indexes
{
    if (_length > 0)
    {
        memcpy(indexes, _indexes, sizeof(NSUInteger) * _length);
    }
}

- (void)getIndexes:(NSUInteger *)indexes range:(NSRange)positionRange
{
    if (positionRange.location > _length || positionRange.length > _length - positionRange.location)
    {
        [NSException raise:NSRangeException format:@"*** -[NSIndexPath getIndexes:range:]: range {%lu, %lu} out of bounds for length %lu",
            (unsigned long)positionRange.location, (unsigned long)positionRange.length, (unsigned long)_length];
        return;
    }
    if (positionRange.length > 0)
    {
        memcpy(indexes, _indexes + positionRange.location, sizeof(NSUInteger) * positionRange.length);
    }
}

- (NSInteger)item
{
    return (NSInteger)[self indexAtPosition:1];
}

- (NSInteger)section
{
    return (NSInteger)[self indexAtPosition:0];
}

- (NSComparisonResult)compare:(NSIndexPath *)otherObject
{
    NSUInteger l1 = [self length];
    NSUInteger l2 = [otherObject length];
    for (NSUInteger pos = 0; pos < MIN(l1, l2); pos ++)
    {
        NSUInteger i1 = [self indexAtPosition:pos];
        NSUInteger i2 = [otherObject indexAtPosition:pos];
        if (i1 < i2)
        {
            return NSOrderedAscending;
        }
        else if (i1 > i2)
        {
            return NSOrderedDescending;
        }
    }
    if (l1 < l2)
    {
        return NSOrderedAscending;
    }
    else if (l1 > l2)
    {
        return NSOrderedDescending;
    }

    return NSOrderedSame;
}

@end
