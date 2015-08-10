//
//  WLUpdateNotification.m
//  moji
//
//  Created by Ravenpod on 4/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUpdateNotification.h"

@implementation WLUpdateNotification

+ (BOOL)isSupportedType:(WLNotificationType)type {
    return type == WLNotificationUpdateAvailable;
}

- (void)fetch:(WLBlock)success failure:(WLFailureBlock)failure {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@",@(WLConstants.appStoreID)]]];
    if (success) success();
}

- (BOOL)supportsApplicationState:(UIApplicationState)state {
    return state == UIApplicationStateInactive;
}

@end
