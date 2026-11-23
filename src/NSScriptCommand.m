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

#import <Foundation/NSScriptCommand.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>

@implementation NSScriptCommand

+ (NSScriptCommand *)currentCommand
{
    return nil;
}

- (void)dealloc
{
    [_arguments release];
    [_scriptErrorString release];
    [super dealloc];
}

- (NSDictionary *)arguments
{
    return _arguments ? _arguments : [NSDictionary dictionary];
}

- (NSDictionary *)evaluatedArguments
{
    return [self arguments];
}

- (id)performDefaultImplementation
{
    return nil;
}

- (void)setArguments:(NSDictionary *)arguments
{
    NSDictionary *copy = [arguments copy];
    [_arguments release];
    _arguments = copy;
}

- (void)setScriptErrorNumber:(NSInteger)errorNumber
{
    _scriptErrorNumber = errorNumber;
}

- (void)setScriptErrorString:(NSString *)errorString
{
    NSString *copy = [errorString copy];
    [_scriptErrorString release];
    _scriptErrorString = copy;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if (!(self = [super init]))
		return nil;
	_arguments = [[aDecoder decodeObjectForKey:@"arguments"] copy];
	_scriptErrorNumber = [aDecoder decodeIntegerForKey:@"scriptErrorNumber"];
	_scriptErrorString = [[aDecoder decodeObjectForKey:@"scriptErrorString"] copy];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_arguments forKey:@"arguments"];
	[aCoder encodeInteger:_scriptErrorNumber forKey:@"scriptErrorNumber"];
	[aCoder encodeObject:_scriptErrorString forKey:@"scriptErrorString"];
}

@end
