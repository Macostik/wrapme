//
//  WLEntry+LocalNotifications.m
//  moji
//
//  Created by Sergey Maximenko on 8/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntry+LocalNotifications.h"
#import "WLNotification.h"

@implementation WLEntry (LocalNotifications)

- (BOOL)locallyNotifiableNotification:(WLNotification *)notification {
    return YES;
}

- (UILocalNotification *)localNotificationForNotification:(WLNotification *)notification {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    NSDictionary *entry = [notification.entry dictionaryRepresentation];
    if (entry) {
        localNotification.userInfo = @{@"type":@(notification.type),@"entry":entry};
    }
    if ([localNotification respondsToSelector:@selector(setAlertTitle:)]) {
        localNotification.alertTitle = [self localNotificationAlertTitleForNotification:notification];
    }
    localNotification.alertBody = [self localNotificationAlertBodyForNotification:notification];
    localNotification.soundName = WLSoundFileName([self localNotificationSoundNameForNotification:notification]);
    localNotification.category = [self localNotificationCategoryForNotification:notification];
    return localNotification;
}

- (NSString *)localNotificationAlertTitleForNotification:(WLNotification *)notification {return nil;}

- (NSString *)localNotificationAlertBodyForNotification:(WLNotification *)notification {return nil;}

- (WLSound)localNotificationSoundNameForNotification:(WLNotification *)notification {return WLSound_Off;}

- (NSString *)localNotificationCategoryForNotification:(WLNotification *)notification {return nil;}

@end

@implementation WLContribution (LocalNotifications) @end

@implementation WLUser (LocalNotifications)

- (WLSound)localNotificationSoundNameForNotification:(WLNotification *)notification {
    return WLSound_s01;
}

@end

@implementation WLWrap (LocalNotifications)

- (BOOL)locallyNotifiableNotification:(WLNotification *)notification {
    return notification.requester != [WLUser currentUser];
}

- (NSString *)localNotificationAlertTitleForNotification:(WLNotification *)notification {
    return WLLS(@"APNS_TT01");
}

- (NSString *)localNotificationAlertBodyForNotification:(WLNotification *)notification {
    NSString *name = notification.requester.name ? : notification.data[@"invited_by_name"];
    return [NSString stringWithFormat:WLLS(@"APNS_MSG01"), name ? : self.contributor.name, self.name];
}

@end

@implementation WLCandy (LocalNotifications)

- (NSString *)localNotificationAlertTitleForNotification:(WLNotification *)notification {
    if (notification.type == WLNotificationCandyAdd) {
        return WLLS(@"APNS_TT02");
    } else if (notification.type == WLNotificationCandyUpdate) {
        return WLLS(@"APNS_TT05");
    }
    return nil;
}

- (NSString *)localNotificationAlertBodyForNotification:(WLNotification *)notification {
    if (notification.type == WLNotificationCandyAdd) {
        return [NSString stringWithFormat:WLLS(@"APNS_MSG02"), self.contributor.name, self.wrap.name];
    } else if (notification.type == WLNotificationCandyUpdate) {
        return [NSString stringWithFormat:WLLS(@"APNS_MSG05"), self.editor.name];
    }
    return nil;
}

- (BOOL)locallyNotifiableNotification:(WLNotification *)notification {
    return self.wrap.isCandyNotifiable;
}

@end

@implementation WLMessage (LocalNotifications)

- (NSString *)localNotificationAlertTitleForNotification:(WLNotification *)notification {
    return WLLS(@"APNS_TT04");
}

- (NSString *)localNotificationAlertBodyForNotification:(WLNotification *)notification {
    return [NSString stringWithFormat:WLLS(@"APNS_MSG04"), self.contributor.name, self.text, self.wrap.name];
}

- (WLSound)localNotificationSoundNameForNotification:(WLNotification *)notification {
    return WLSound_s03;
}

- (NSString *)localNotificationCategoryForNotification:(WLNotification *)notification {
    return @"chat";
}

- (BOOL)locallyNotifiableNotification:(WLNotification *)notification {
    return self.wrap.isChatNotifiable;
}

@end

@implementation WLComment (LocalNotifications)

- (NSString *)localNotificationAlertTitleForNotification:(WLNotification *)notification {
    return WLLS(@"APNS_TT03");
}

- (NSString *)localNotificationAlertBodyForNotification:(WLNotification *)notification {
    return [NSString stringWithFormat:WLLS(@"APNS_MSG03"), self.contributor.name, self.text];
}

- (WLSound)localNotificationSoundNameForNotification:(WLNotification *)notification {
    return WLSound_s02;
}

@end