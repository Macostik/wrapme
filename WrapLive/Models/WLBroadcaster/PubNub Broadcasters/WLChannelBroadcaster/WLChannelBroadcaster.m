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

- (void)setup {
	[[WLNotificationBroadcaster broadcaster] addReceiver:self];
}

@end
