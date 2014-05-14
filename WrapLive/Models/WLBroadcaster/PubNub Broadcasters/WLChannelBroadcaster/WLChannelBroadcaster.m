//
//  WLChannelBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 14.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChannelBroadcaster.h"
#import "NSDictionary+Extended.h"

@implementation WLChannelBroadcaster

- (void)dealloc {
	[[WLMessageBroadcaster broadcaster] unsubscribe:self];
}

- (void)addReceiver:(id<WLBroadcastReceiver>)receiver {
	[super addReceiver:receiver];
	[[WLMessageBroadcaster broadcaster] addReceiver:self];
}

- (void)didReceiveMessage:(WLMessageType)type data:(NSDictionary *)data {
	
}

#pragma mark - WLMessageBroadcastReceiver

- (NSString *)broadcasterChannelName:(WLMessageBroadcaster *)broadcaster {
	return nil;
}

- (void)broadcaster:(WLMessageBroadcaster *)broadcaster messageReceived:(PNMessage *)message {
	NSDictionary* data = message.message;
	if ([data isKindOfClass:[NSDictionary class]]) {
		WLMessageType type = [data integerForKey:@"pn_type"];
		[self didReceiveMessage:type data:data];
	}
}

@end
