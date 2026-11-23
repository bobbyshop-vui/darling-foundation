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

#import <Foundation/Foundation.h>

@class NSDate;
@protocol NSUserActivityDelegate;

@interface NSUserActivity : NSObject {
    NSString *_activityType;
    NSString *_title;
    NSDictionary *_userInfo;
    NSDate *_expirationDate;
    NSSet *_keywords;
    id<NSUserActivityDelegate> _delegate;
    BOOL _isCurrent;
    BOOL _isInvalidated;
}

- (instancetype)initWithActivityType:(NSString *)activityType;

@property (readonly, copy) NSString *activityType;
@property (nullable, copy) NSString *title;
@property (nullable, copy) NSDictionary *userInfo;
@property (nullable, copy) NSDate *expirationDate;
@property (copy) NSSet *keywords;
@property (nullable, assign) id<NSUserActivityDelegate> delegate;

- (void)invalidate;
- (void)resignCurrent;

@end
