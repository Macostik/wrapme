//
//  WLEntry+LocalNotifications.h
//  moji
//
//  Created by Sergey Maximenko on 8/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <16wrapKit/16wrapKit.h>
#import "WLSoundPlayer.h"

@class WLNotification;

@interface WLEntry (LocalNotifications)

- (BOOL)locallyNotifiableNotification:(WLNotification *)notification;

- (UILocalNotification *)localNotificationForNotification:(WLNotification *)notification;

- (NSString *)localNotificationAlertTitleForNotification:(WLNotification *)notification;

- (NSString *)localNotificationAlertBodyForNotification:(WLNotification *)notification;

- (WLSound)localNotificationSoundNameForNotification:(WLNotification *)notification;

- (NSString *)localNotificationCategoryForNotification:(WLNotification *)notification;

@end

@interface WLContribution (LocalNotifications) @end

@interface WLUser (LocalNotifications) @end

@interface WLWrap (LocalNotifications) @end

@interface WLCandy (LocalNotifications) @end

@interface WLMessage (LocalNotifications) @end

@interface WLComment (LocalNotifications) @end