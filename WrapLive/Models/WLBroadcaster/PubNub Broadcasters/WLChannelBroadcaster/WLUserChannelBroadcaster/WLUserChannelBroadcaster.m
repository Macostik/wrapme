//
//  WLUserChannelBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 14.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUserChannelBroadcaster.h"
#import "WLUser.h"
#import "WLAPIManager.h"
#import "NSString+Additions.h"
#import "WLToast.h"
#import "WLWrapChannelBroadcaster.h"
#import "WLEntryState.h"

@interface WLUserChannelBroadcaster ()

@end

@implementation WLUserChannelBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

#pragma mark - WLNotificationReceiver

- (void)broadcaster:(WLNotificationBroadcaster *)broadcaster notificationReceived:(WLNotification *)notification {
	__weak typeof(self)weakSelf = self;
	[notification.wrap fetch:^(WLWrap *wrap) {
		if (notification.type == WLNotificationContributorAddition) {
			[weakSelf broadcast:@selector(broadcaster:didBecomeContributor:) object:wrap];
		} else if (notification.type == WLNotificationContributorDeletion) {
			[weakSelf broadcast:@selector(broadcaster:didResignContributor:) object:wrap];
		}
	} failure:^(NSError *error) {
	}];
}

- (BOOL)broadcaster:(WLNotificationBroadcaster *)broadcaster shouldReceiveNotification:(WLNotification *)notification {
	return (notification.type == WLNotificationContributorAddition || notification.type == WLNotificationContributorDeletion);
}

@end
