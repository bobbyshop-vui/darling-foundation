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

#import <Foundation/NSUserNotification.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSAttributedString.h>

@implementation NSUserNotification

- (NSString *)title { return _title; }
- (void)setTitle:(NSString *)title
{
	if (_title != title) { [_title release]; _title = [title copy]; }
}

- (NSString *)subtitle { return _subtitle; }
- (void)setSubtitle:(NSString *)subtitle
{
	if (_subtitle != subtitle) { [_subtitle release]; _subtitle = [subtitle copy]; }
}

- (NSString *)informativeText { return _informativeText; }
- (void)setInformativeText:(NSString *)informativeText
{
	if (_informativeText != informativeText) { [_informativeText release]; _informativeText = [informativeText copy]; }
}

- (NSString *)actionButtonTitle { return _actionButtonTitle ?: @"Show"; }
- (void)setActionButtonTitle:(NSString *)actionButtonTitle
{
	NSString *value = actionButtonTitle ?: @"Show";
	if (_actionButtonTitle != value) { [_actionButtonTitle release]; _actionButtonTitle = [value copy]; }
}

- (NSDictionary *)userInfo { return _userInfo; }
- (void)setUserInfo:(NSDictionary *)userInfo
{
	if (_userInfo != userInfo) { [_userInfo release]; _userInfo = [userInfo copy]; }
}

- (NSString *)soundName { return _soundName; }
- (void)setSoundName:(NSString *)soundName
{
	if (_soundName != soundName) { [_soundName release]; _soundName = [soundName copy]; }
}

- (NSString *)identifier { return _identifier; }
- (void)setIdentifier:(NSString *)identifier
{
	if (_identifier != identifier) { [_identifier release]; _identifier = [identifier copy]; }
}

- (NSImage *)contentImage { return _contentImage; }
- (void)setContentImage:(NSImage *)contentImage
{
	if (_contentImage != contentImage) { [_contentImage release]; _contentImage = [contentImage copy]; }
}

- (NSAttributedString *)response { return _response; }

- (void)dealloc
{
	[_title release];
	[_subtitle release];
	[_informativeText release];
	[_actionButtonTitle release];
	[_userInfo release];
	[_soundName release];
	[_identifier release];
	[_contentImage release];
	[_response release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	NSLog(@"[NSUserNotification copyWithZone:]");
	return nil;
}

@end

@implementation NSUserNotificationAction

- (NSString *)identifier { return _identifier; }
- (NSString *)title { return _title; }

- (void)dealloc
{
	[_identifier release];
	[_title release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	NSLog(@"[NSUserNotificationAction copyWithZone:]");
	return nil;
}

@end

@implementation NSUserNotificationCenter

static NSUserNotificationCenter *_defaultUserNotificationCenter = nil;

@synthesize delegate = _delegate;

- (instancetype)init
{
	self = [super init];
	if (self) {
		_scheduledNotifications = [[NSMutableArray alloc] init];
		_deliveredNotifications = [[NSMutableArray alloc] init];
	}
	return self;
}

+ (NSUserNotificationCenter *)defaultUserNotificationCenter {
	if (_defaultUserNotificationCenter == nil) {
		_defaultUserNotificationCenter = [[NSUserNotificationCenter alloc] init];
	}

	return _defaultUserNotificationCenter;
}

- (NSArray *)scheduledNotifications
{
	return [[_scheduledNotifications copy] autorelease];
}

- (void)setScheduledNotifications:(NSArray *)notifications
{
	NSMutableArray *newNotifications = notifications ? [notifications mutableCopy] : [[NSMutableArray alloc] init];
	[_scheduledNotifications release];
	_scheduledNotifications = newNotifications;
}

- (NSArray *)deliveredNotifications
{
	return [[_deliveredNotifications copy] autorelease];
}

- (void)scheduleNotification:(NSUserNotification *)notification
{
	if (notification)
		[_scheduledNotifications addObject:notification];
}

- (void)removeScheduledNotification:(NSUserNotification *)notification
{
	NSUInteger index = 0;
	while (index < [_scheduledNotifications count]) {
		if ([_scheduledNotifications objectAtIndex:index] == notification)
			[_scheduledNotifications removeObjectAtIndex:index];
		else
			index++;
	}
}

- (void)deliverNotification:(NSUserNotification *)notification {
	if (!notification)
		return;
	[self removeScheduledNotification:notification];
	if (![_deliveredNotifications containsObject:notification])
		[_deliveredNotifications addObject:notification];
}

- (void)removeDeliveredNotification:(NSUserNotification *)notification {
	NSUInteger index = 0;
	while (index < [_deliveredNotifications count]) {
		if ([_deliveredNotifications objectAtIndex:index] == notification)
			[_deliveredNotifications removeObjectAtIndex:index];
		else
			index++;
	}
}

- (void)removeAllDeliveredNotifications
{
	[_deliveredNotifications removeAllObjects];
}

- (void)dealloc
{
	[_scheduledNotifications release];
	[_deliveredNotifications release];
	[super dealloc];
}

@end

NSString * const NSUserNotificationDefaultSoundName = @"DefaultSoundName";
