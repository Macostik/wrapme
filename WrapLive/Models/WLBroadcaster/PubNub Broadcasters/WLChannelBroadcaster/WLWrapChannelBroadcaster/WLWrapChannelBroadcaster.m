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
	if (notification.type == WLNotificationImageCandyDeletion) {
		[self.wrap removeCandy:notification.candy];
		[self broadcast:@selector(broadcaster:didDeleteCandy:) object:notification.candy];
	} else if (notification.type == WLNotificationCandyCommentDeletion) {
		[self.candy removeComment:notification.comment];
		[self broadcast:@selector(broadcaster:didDeleteComment:) object:self.candy];
	} else {
        [self.wrap addCandy:notification.candy];
        if (notification.type == WLNotificationImageCandyAddition) {
            [self broadcast:@selector(broadcaster:didAddCandy:) object:notification.candy];
        } else if (notification.type == WLNotificationChatCandyAddition) {
            [self broadcast:@selector(broadcaster:didAddChatMessage:) object:notification.candy];
        } else if (notification.type == WLNotificationCandyCommentAddition) {
            [self broadcast:@selector(broadcaster:didAddComment:) object:notification.candy];
        }
    }
}

- (BOOL)broadcaster:(WLNotificationBroadcaster *)broadcaster shouldReceiveNotification:(WLNotification *)notification {
	if (self.wrap && ![notification.wrap isEqualToEntry:self.wrap]) {
		return NO;
	}
	if (self.candy && ![notification.candy isEqualToEntry:self.candy]) {
		return NO;
	}
	return (notification.type != WLNotificationContributorAddition && notification.type != WLNotificationContributorDeletion && notification.type != WLNotificationWrapDeletion);
}

@end
