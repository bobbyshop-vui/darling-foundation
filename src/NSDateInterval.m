/*
 This file is part of Darling.

 Copyright (C) 2019 Lubos Dolezel

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

#import <Foundation/NSDateInterval.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSException.h>

@implementation NSDateInterval

- (instancetype)init
{
    return [self initWithStartDate:[NSDate date] duration:0];
}

- (instancetype)initWithStartDate:(NSDate *)startDate duration:(NSTimeInterval)duration
{
    if (duration < 0)
    {
        [self release];
        [NSException raise:NSInvalidArgumentException format:@"Interval duration cannot be negative"];
        return nil;
    }
    if (startDate == nil)
    {
        [self release];
        [NSException raise:NSInvalidArgumentException format:@"Interval start date cannot be nil"];
        return nil;
    }
    self = [super init];
    if (self != nil)
    {
        _startDate = [startDate copy];
        _duration = duration;
    }
    return self;
}

- (instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    if (startDate == nil || endDate == nil)
    {
        [self release];
        [NSException raise:NSInvalidArgumentException format:@"Interval dates cannot be nil"];
        return nil;
    }
    NSTimeInterval duration = [endDate timeIntervalSinceDate:startDate];
    if (duration < 0)
    {
        [self release];
        [NSException raise:NSInvalidArgumentException format:@"Interval end date cannot precede its start date"];
        return nil;
    }
    return [self initWithStartDate:startDate duration:duration];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (![coder allowsKeyedCoding])
    {
        [self release];
        [NSException raise:NSInvalidArgumentException format:@"NSDateInterval requires keyed coding"];
        return nil;
    }
    NSDate *start = [coder decodeObjectOfClass:[NSDate class] forKey:@"NS.startDate"];
    NSTimeInterval duration = [coder decodeDoubleForKey:@"NS.duration"];
    if (start == nil || duration < 0)
    {
        [self release];
        return nil;
    }
    return [self initWithStartDate:start duration:duration];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_startDate forKey:@"NS.startDate"];
    [coder encodeDouble:_duration forKey:@"NS.duration"];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[NSDateInterval allocWithZone:zone] initWithStartDate:_startDate duration:_duration];
}

- (void)dealloc
{
    [_startDate release];
    [super dealloc];
}

- (NSDate *)startDate
{
    return [[_startDate copy] autorelease];
}

- (NSDate *)endDate
{
    return [_startDate dateByAddingTimeInterval:_duration];
}

- (NSTimeInterval)duration
{
    return _duration;
}

- (NSComparisonResult)compare:(NSDateInterval *)dateInterval
{
    NSComparisonResult result = [_startDate compare:dateInterval->_startDate];
    if (result != NSOrderedSame)
    {
        return result;
    }
    if (_duration < dateInterval->_duration)
    {
        return NSOrderedAscending;
    }
    if (_duration > dateInterval->_duration)
    {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}

- (BOOL)isEqualToDateInterval:(NSDateInterval *)dateInterval
{
    return [self compare:dateInterval] == NSOrderedSame;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    if (![object isKindOfClass:[NSDateInterval class]])
    {
        return NO;
    }
    return [self isEqualToDateInterval:object];
}

- (NSUInteger)hash
{
    return [_startDate hash] ^ (NSUInteger)_duration;
}

- (BOOL)intersectsDateInterval:(NSDateInterval *)dateInterval
{
    NSTimeInterval start = [_startDate timeIntervalSinceReferenceDate];
    NSTimeInterval otherStart = [dateInterval->_startDate timeIntervalSinceReferenceDate];
    return start <= otherStart + dateInterval->_duration && otherStart <= start + _duration;
}

- (NSDateInterval *)intersectionWithDateInterval:(NSDateInterval *)dateInterval
{
    if (![self intersectsDateInterval:dateInterval])
    {
        return nil;
    }
    NSTimeInterval start = [_startDate timeIntervalSinceReferenceDate];
    NSTimeInterval otherStart = [dateInterval->_startDate timeIntervalSinceReferenceDate];
    NSTimeInterval newStart = start > otherStart ? start : otherStart;
    NSTimeInterval end = start + _duration;
    NSTimeInterval otherEnd = otherStart + dateInterval->_duration;
    NSTimeInterval newEnd = end < otherEnd ? end : otherEnd;
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:newStart];
    return [[[NSDateInterval alloc] initWithStartDate:date duration:newEnd - newStart] autorelease];
}

- (BOOL)containsDate:(NSDate *)date
{
    NSTimeInterval t = [date timeIntervalSinceReferenceDate];
    NSTimeInterval start = [_startDate timeIntervalSinceReferenceDate];
    return t >= start && t <= start + _duration;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ + %g seconds", _startDate, _duration];
}

@end
