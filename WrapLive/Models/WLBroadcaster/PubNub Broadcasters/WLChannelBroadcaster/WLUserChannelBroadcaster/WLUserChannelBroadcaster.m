//
//  WLUserChannelBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 14.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUserChannelBroadcaster.h"
#import "WLUser.h"

@interface WLUserChannelBroadcaster ()

@end

@implementation WLUserChannelBroadcaster

- (void)didReceiveMessage:(WLMessageType)type data:(NSDictionary *)data {
	if (type == WLMessageContributorAddition) {
		[self broadcast:@selector(broadcasterDidAddContributor:)];
	} else if (type == WLMessageContributorDeletion) {
		[self broadcast:@selector(broadcasterDidDeleteContributor:)];
	}
}

#pragma mark - WLMessageBroadcastReceiver

- (NSString *)broadcasterChannelName:(WLMessageBroadcaster *)broadcaster {
	return [WLUser currentUser].identifier;
}

@end
