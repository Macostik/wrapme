//
//  WLChannelBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 14.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLMessageBroadcaster.h"

typedef NS_ENUM(NSUInteger, WLMessageType) {
	WLMessageContributorAddition  = 100,
	WLMessageContributorDeletion  = 200,
	WLMessageImageCandyAddition   = 300,
	WLMessageImageCandyDeletion   = 400,
	WLMessageCandyCommentAddition = 500,
	WLMessageCandyCommentDeletion = 600,
	WLMessageChatCandyAddition    = 700,
};

@interface WLChannelBroadcaster : WLBroadcaster <WLMessageBroadcastReceiver>

- (void)didReceiveMessage:(WLMessageType)type data:(NSDictionary*)data;

@end
