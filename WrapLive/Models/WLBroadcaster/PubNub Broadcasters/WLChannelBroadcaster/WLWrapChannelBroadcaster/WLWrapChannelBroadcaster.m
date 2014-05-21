//
//  WLWrapPubNubBroadcaster.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapChannelBroadcaster.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "NSString+Additions.h"
#import "WLAPIManager.h"
#import "WLEntryState.h"

@interface WLWrapChannelBroadcaster ()

@end

@implementation WLWrapChannelBroadcaster

- (instancetype)initWithReceiver:(id<WLWrapChannelBroadcastReceiver>)receiver wrap:(WLWrap *)wrap {
    self = [super init];
    if (self) {
        [self addReceiver:receiver withWrap:wrap];
    }
    return self;
}

- (void)addReceiver:(id<WLBroadcastReceiver>)receiver withWrap:(WLWrap *)wrap {
	self.wrap = wrap;
	[self addReceiver:receiver];
}

#pragma mark - WLNotificationReceiver

- (void)broadcaster:(WLNotificationBroadcaster *)broadcaster notificationReceived:(WLNotification *)notification {
	[self.wrap setUpdated:YES];
	__weak typeof(self)weakSelf = self;
	[notification.candy fetch:self.wrap success:^(WLCandy *candy) {
		if (notification.type == WLNotificationImageCandyAddition) {
			[weakSelf broadcast:@selector(broadcaster:didAddCandy:) object:candy];
		} else if (notification.type == WLNotificationImageCandyDeletion) {
			[weakSelf broadcast:@selector(broadcaster:didDeleteCandy:) object:candy];
		} else if (notification.type == WLNotificationChatCandyAddition) {
			[candy setUpdated:YES];
			[weakSelf broadcast:@selector(broadcaster:didAddChatMessage:) object:candy];
		} else if (notification.type == WLNotificationCandyCommentAddition) {
			[candy setUpdated:YES];
			[weakSelf broadcast:@selector(broadcaster:didAddComment:) object:candy];
		} else if (notification.type == WLNotificationCandyCommentDeletion) {
			[weakSelf broadcast:@selector(broadcaster:didDeleteComment:) object:candy];
		}
	} failure:^(NSError *error) {
	}];
}

- (BOOL)broadcaster:(WLNotificationBroadcaster *)broadcaster shouldReceiveNotification:(WLNotification *)notification {
	if (self.wrap && ![notification.wrap isEqualToEntry:self.wrap]) {
		return NO;
	}
	if (self.candy && ![notification.candy isEqualToEntry:self.candy]) {
		return NO;
	}
	return (notification.type != WLNotificationContributorAddition && notification.type != WLNotificationContributorDeletion);
}

@end
