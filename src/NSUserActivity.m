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

#import <Foundation/NSUserActivity.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>

@implementation NSUserActivity

- (instancetype)initWithActivityType:(NSString *)activityType
{
    self = [super init];
    if (self) {
        _activityType = [(activityType ?: @"") copy];
        _keywords = [[NSSet alloc] init];
    }
    return self;
}

- (NSString *)activityType
{
    return _activityType ?: @"";
}

- (NSString *)title
{
    return _title;
}

- (void)setTitle:(NSString *)title
{
    if (_title != title) {
        [_title release];
        _title = [title copy];
    }
}

- (NSDictionary *)userInfo
{
    return _userInfo;
}

- (void)setUserInfo:(NSDictionary *)userInfo
{
    if (_userInfo != userInfo) {
        [_userInfo release];
        _userInfo = [userInfo copy];
    }
}

- (NSDate *)expirationDate
{
    return _expirationDate;
}

- (void)setExpirationDate:(NSDate *)expirationDate
{
    if (_expirationDate != expirationDate) {
        [_expirationDate release];
        _expirationDate = [expirationDate copy];
    }
}

- (NSSet *)keywords
{
    return _keywords ?: [NSSet set];
}

- (void)setKeywords:(NSSet *)keywords
{
    NSSet *newKeywords = keywords ?: [NSSet set];
    if (_keywords != newKeywords) {
        [_keywords release];
        _keywords = [newKeywords copy];
    }
}

- (id<NSUserActivityDelegate>)delegate
{
    return _delegate;
}

- (void)setDelegate:(id<NSUserActivityDelegate>)delegate
{
    _delegate = delegate;
}

- (void)resignCurrent
{
    _isCurrent = NO;
}

- (void)invalidate
{
    _isInvalidated = YES;
    [self resignCurrent];
}

- (void)dealloc
{
    [_activityType release];
    [_title release];
    [_userInfo release];
    [_expirationDate release];
    [_keywords release];
    [super dealloc];
}

@end
