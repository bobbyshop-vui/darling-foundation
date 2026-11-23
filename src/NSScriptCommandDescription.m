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

#import <Foundation/NSScriptCommandDescription.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>

@implementation NSScriptCommandDescription

- (void)dealloc
{
	[_commandName release];
	[_returnType release];
	[_suiteName release];
	[super dealloc];
}

- (NSString *)commandName
{
	return _commandName ? _commandName : @"";
}

- (NSString *)returnType
{
	return _returnType;
}

- (NSString *)suiteName
{
	return _suiteName ? _suiteName : @"";
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if (!(self = [super init]))
		return nil;
	_commandName = [[aDecoder decodeObjectForKey:@"commandName"] copy];
	_returnType = [[aDecoder decodeObjectForKey:@"returnType"] copy];
	_suiteName = [[aDecoder decodeObjectForKey:@"suiteName"] copy];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_commandName forKey:@"commandName"];
	[aCoder encodeObject:_returnType forKey:@"returnType"];
	[aCoder encodeObject:_suiteName forKey:@"suiteName"];
}

@end
