/*
 This file is part of Darling.

 Copyright (C) 2019 Lubos Dolezel

 Darling is free softwareyou can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Darling is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Darling.  If not, see <http//www.gnu.org/licenses/>.
*/

#import <Foundation/NSScriptObjectSpecifiers.h>
#import <Foundation/NSScriptClassDescription.h>
#import <Foundation/NSScriptWhoseTest.h>
#import <Foundation/NSAppleEventDescriptor.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>

@implementation NSScriptObjectSpecifier

- (void)dealloc
{
	[_containerClassDescription release];
	[_containerSpecifier release];
	[_key release];
	[super dealloc];
}

- (instancetype)initWithContainerClassDescription:(NSScriptClassDescription *)classDescription containerSpecifier:(NSScriptObjectSpecifier *)containerSpecifier key:(NSString *)key
{
	if (!(self = [super init]))
		return nil;
	_containerClassDescription = [classDescription retain];
	_containerSpecifier = [containerSpecifier retain];
	_key = [key copy];
	return self;
}

- (instancetype)initWithContainerSpecifier:(NSScriptObjectSpecifier *)containerSpecifier key:(NSString *)key
{
	return [self initWithContainerClassDescription:nil containerSpecifier:containerSpecifier key:key];
}

- (NSString *)key
{
	return _key ? _key : @"";
}

- (void)setKey:(NSString *)key
{
	NSString *copy = [key copy];
	if (_key != copy)
	{
		[_key release];
		_key = copy;
	}
	else
	{
		[copy release];
	}
}

- (NSAppleEventDescriptor *)descriptor
{
	// Cocotron's Apple Event descriptor does not encode object-specifier records yet.
	return [NSAppleEventDescriptor nullDescriptor];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if (!(self = [super init]))
		return nil;
	_containerClassDescription = [[aDecoder decodeObjectForKey:@"containerClassDescription"] retain];
	_containerSpecifier = [[aDecoder decodeObjectForKey:@"containerSpecifier"] retain];
	_key = [[aDecoder decodeObjectForKey:@"key"] copy];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_containerClassDescription forKey:@"containerClassDescription"];
	[aCoder encodeObject:_containerSpecifier forKey:@"containerSpecifier"];
	[aCoder encodeObject:_key forKey:@"key"];
}

- (BOOL)supportsSecureCoding
{
	return YES;
}

@end

@implementation NSObject (NSScriptObjectSpecifiers)
@end

@implementation NSIndexSpecifier

- (instancetype)initWithContainerClassDescription:(NSScriptClassDescription *)classDescription containerSpecifier:(NSScriptObjectSpecifier *)containerSpecifier key:(NSString *)key index:(NSInteger)index
{
	if (!(self = [super initWithContainerClassDescription:classDescription containerSpecifier:containerSpecifier key:key]))
		return nil;
	_index = index;
	return self;
}

- (NSInteger)index
{
	return _index;
}

- (void)setIndex:(NSInteger)index
{
	_index = index;
}

@end

@implementation NSMiddleSpecifier
@end

@implementation NSNameSpecifier

- (void)dealloc
{
	[_name release];
	[super dealloc];
}

- (instancetype)initWithContainerClassDescription:(NSScriptClassDescription *)classDescription containerSpecifier:(NSScriptObjectSpecifier *)containerSpecifier key:(NSString *)key name:(NSString *)name
{
	if (!(self = [super initWithContainerClassDescription:classDescription containerSpecifier:containerSpecifier key:key]))
		return nil;
	_name = [name copy];
	return self;
}

- (NSString *)name
{
	return _name ? _name : @"";
}

- (void)setName:(NSString *)name
{
	NSString *copy = [name copy];
	if (_name != copy)
	{
		[_name release];
		_name = copy;
	}
	else
	{
		[copy release];
	}
}

@end

@implementation NSPositionalSpecifier

- (void)dealloc
{
	[_objectSpecifier release];
	[super dealloc];
}

- (instancetype)initWithPosition:(NSInsertionPosition)position objectSpecifier:(NSScriptObjectSpecifier *)objectSpecifier
{
	if (!(self = [super init]))
		return nil;
	_position = position;
	_objectSpecifier = [objectSpecifier retain];
	return self;
}

- (void)evaluate
{
	if (_evaluated)
		return;
	_evaluated = YES;

	NSInteger referenceIndex = 0;
	if ([_objectSpecifier isKindOfClass:[NSIndexSpecifier class]])
		referenceIndex = [(NSIndexSpecifier *)_objectSpecifier index];

	switch (_position)
	{
		case NSPositionBefore:
		case NSPositionReplace:
			_insertionIndex = referenceIndex;
			break;
		case NSPositionAfter:
			_insertionIndex = referenceIndex + 1;
			break;
		case NSPositionBeginning:
			_insertionIndex = 0;
			break;
		case NSPositionEnd:
		default:
			_insertionIndex = referenceIndex;
			break;
	}
}

- (NSInteger)insertionIndex
{
	[self evaluate];
	return _insertionIndex;
}

- (NSScriptObjectSpecifier *)objectSpecifier
{
	return _objectSpecifier;
}

- (NSInsertionPosition)position
{
	return _position;
}

@end

@implementation NSPropertySpecifier
@end

@implementation NSRandomSpecifier
@end

@implementation NSRangeSpecifier
@end

@implementation NSRelativeSpecifier
@end

@implementation NSUniqueIDSpecifier

- (void)dealloc
{
	[_uniqueID release];
	[super dealloc];
}

- (instancetype)initWithContainerClassDescription:(NSScriptClassDescription *)classDescription containerSpecifier:(NSScriptObjectSpecifier *)containerSpecifier key:(NSString *)key uniqueID:(id)uniqueID
{
	if (!(self = [super initWithContainerClassDescription:classDescription containerSpecifier:containerSpecifier key:key]))
		return nil;
	_uniqueID = [uniqueID retain];
	return self;
}

- (void)setUniqueID:(id)uniqueID
{
	if (_uniqueID != uniqueID)
	{
		[uniqueID retain];
		[_uniqueID release];
		_uniqueID = uniqueID;
	}
}

- (id)uniqueID
{
	return _uniqueID;
}

@end

@implementation NSWhoseSpecifier

- (void)dealloc
{
	[_test release];
	[super dealloc];
}

- (void)setTest:(NSScriptWhoseTest *)test
{
	if (_test != test)
	{
		[test retain];
		[_test release];
		_test = test;
	}
}

- (NSScriptWhoseTest *)test
{
	if (!_test)
		_test = [[NSScriptWhoseTest alloc] init];
	return _test;
}

@end
