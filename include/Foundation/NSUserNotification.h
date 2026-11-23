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

#import <Foundation/NSString.h>

@class NSArray, NSMutableArray, NSDictionary, NSImage, NSAttributedString;

@interface NSUserNotification : NSObject <NSCopying> {
    NSString *_title;
    NSString *_subtitle;
    NSString *_informativeText;
    NSString *_actionButtonTitle;
    NSDictionary *_userInfo;
    NSString *_soundName;
    NSString *_identifier;
    NSImage *_contentImage;
    NSAttributedString *_response;
}

@property (nullable, copy) NSString *title;
@property (nullable, copy) NSString *subtitle;
@property (nullable, copy) NSString *informativeText;
@property (copy) NSString *actionButtonTitle;
@property (nullable, copy) NSDictionary *userInfo;
@property (nullable, copy) NSString *soundName;
@property (nullable, copy) NSString *identifier;
@property (nullable, copy) NSImage *contentImage;
@property (nullable, readonly, copy) NSAttributedString *response;

- (void)setTitle:(NSString *)title;
- (void)setSubtitle:(NSString *)subtitle;
- (void)setInformativeText:(NSString *)informativeText;
- (void)setActionButtonTitle:(NSString *)actionButtonTitle;
- (void)setUserInfo:(NSDictionary *)userInfo;
- (void)setSoundName:(NSString *)soundName;
- (void)setIdentifier:(NSString *)identifier;
- (void)setContentImage:(NSImage *)contentImage;
@end

@interface NSUserNotificationAction : NSObject <NSCopying> {
    NSString *_identifier;
    NSString *_title;
}

@property (nullable, readonly, copy) NSString *identifier;
@property (nullable, readonly, copy) NSString *title;
@end

@protocol NSUserNotificationCenterDelegate <NSObject>
@end

@interface NSUserNotificationCenter : NSObject {
    id<NSUserNotificationCenterDelegate> _delegate;
    NSMutableArray *_scheduledNotifications;
    NSMutableArray *_deliveredNotifications;
}

@property(class, readonly, strong) NSUserNotificationCenter *defaultUserNotificationCenter;
@property(assign) id<NSUserNotificationCenterDelegate> delegate;
@property(copy) NSArray *scheduledNotifications;
@property(readonly, copy) NSArray *deliveredNotifications;

- (void)scheduleNotification:(NSUserNotification *)notification;
- (void)removeScheduledNotification:(NSUserNotification *)notification;
- (void)setScheduledNotifications:(NSArray *)notifications;
- (void)removeAllDeliveredNotifications;
- (void)deliverNotification:(NSUserNotification *)notification;
- (void)removeDeliveredNotification:(NSUserNotification *)notification;

@end

FOUNDATION_EXPORT NSString * const NSUserNotificationDefaultSoundName;
