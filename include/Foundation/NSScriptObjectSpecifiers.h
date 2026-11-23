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

#import <Foundation/NSObject.h>

@class NSAppleEventDescriptor, NSScriptClassDescription, NSScriptWhoseTest, NSString;

typedef NSUInteger NSInsertionPosition;
enum {
	NSPositionAfter = 0,
	NSPositionBefore = 1,
	NSPositionBeginning = 2,
	NSPositionEnd = 3,
	NSPositionReplace = 4
};

@interface NSScriptObjectSpecifier : NSObject <NSCoding>
{
@protected
	NSScriptClassDescription *_containerClassDescription;
	NSScriptObjectSpecifier *_containerSpecifier;
	NSString *_key;
}

- (NSAppleEventDescriptor *)descriptor;
- (instancetype)initWithContainerClassDescription:(NSScriptClassDescription *)classDescription containerSpecifier:(NSScriptObjectSpecifier *)containerSpecifier key:(NSString *)key;
- (instancetype)initWithContainerSpecifier:(NSScriptObjectSpecifier *)containerSpecifier key:(NSString *)key;
- (NSString *)key;
- (void)setKey:(NSString *)key;
@end

@interface NSObject (NSScriptObjectSpecifiers)
@end

@interface NSIndexSpecifier : NSScriptObjectSpecifier
{
	NSInteger _index;
}
- (NSInteger)index;
- (instancetype)initWithContainerClassDescription:(NSScriptClassDescription *)classDescription containerSpecifier:(NSScriptObjectSpecifier *)containerSpecifier key:(NSString *)key index:(NSInteger)index;
- (void)setIndex:(NSInteger)index;
@end

@interface NSMiddleSpecifier : NSScriptObjectSpecifier
@end

@interface NSNameSpecifier : NSScriptObjectSpecifier
{
	NSString *_name;
}
- (instancetype)initWithContainerClassDescription:(NSScriptClassDescription *)classDescription containerSpecifier:(NSScriptObjectSpecifier *)containerSpecifier key:(NSString *)key name:(NSString *)name;
- (NSString *)name;
- (void)setName:(NSString *)name;
@end

@interface NSPositionalSpecifier : NSObject
{
	NSScriptObjectSpecifier *_objectSpecifier;
	NSInsertionPosition _position;
	NSInteger _insertionIndex;
	BOOL _evaluated;
}
- (void)evaluate;
- (NSInteger)insertionIndex;
- (instancetype)initWithPosition:(NSInsertionPosition)position objectSpecifier:(NSScriptObjectSpecifier *)objectSpecifier;
- (NSScriptObjectSpecifier *)objectSpecifier;
- (NSInsertionPosition)position;
@end

@interface NSPropertySpecifier : NSScriptObjectSpecifier
@end

@interface NSRandomSpecifier : NSScriptObjectSpecifier
@end

@interface NSRangeSpecifier : NSScriptObjectSpecifier
@end

@interface NSRelativeSpecifier : NSScriptObjectSpecifier
@end

@interface NSUniqueIDSpecifier : NSScriptObjectSpecifier
{
	id _uniqueID;
}
- (instancetype)initWithContainerClassDescription:(NSScriptClassDescription *)classDescription containerSpecifier:(NSScriptObjectSpecifier *)containerSpecifier key:(NSString *)key uniqueID:(id)uniqueID;
- (void)setUniqueID:(id)uniqueID;
- (id)uniqueID;
@end

@interface NSWhoseSpecifier : NSScriptObjectSpecifier
{
	NSScriptWhoseTest *_test;
}
- (void)setTest:(NSScriptWhoseTest *)test;
- (NSScriptWhoseTest *)test;
@end
