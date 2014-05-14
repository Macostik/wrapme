//
//  WLWrapPubNubBroadcaster.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapChannelBroadcaster.h"
#import "WLWrap.h"

@interface WLWrapChannelBroadcaster ()

@end

@implementation WLWrapChannelBroadcaster

- (void)addReceiver:(id<WLBroadcastReceiver>)receiver withWrap:(WLWrap *)wrap {
	self.wrap = wrap;
	[self addReceiver:receiver];
}

- (void)didReceiveMessage:(WLMessageType)type data:(NSDictionary *)data {
	if (type == WLMessageImageCandyAddition) {
		[self broadcast:@selector(broadcasterDidAddCandy:)];
	} else if (type == WLMessageImageCandyDeletion) {
		[self broadcast:@selector(broadcasterDidDeleteCandy:)];
	} else if (type == WLMessageChatCandyAddition) {
		[self broadcast:@selector(broadcasterDidAddChatMessage:)];
	} else if (type == WLMessageCandyCommentAddition) {
		[self broadcast:@selector(broadcasterDidAddComment:)];
	} else if (type == WLMessageCandyCommentDeletion) {
		[self broadcast:@selector(broadcasterDidDeleteComment:)];
	}
}

#pragma mark - WLMessageBroadcastReceiver

- (NSString *)broadcasterChannelName:(WLMessageBroadcaster *)broadcaster {
	return self.wrap.identifier;
}

@end
