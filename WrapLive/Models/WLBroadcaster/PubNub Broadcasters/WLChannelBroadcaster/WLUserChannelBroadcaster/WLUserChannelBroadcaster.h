//
//  WLUserChannelBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 14.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChannelBroadcaster.h"

@class WLUserChannelBroadcaster;

@protocol WLUserChannelBroadcastReceiver <NSObject>

@optional

- (void)broadcasterDidAddContributor:(WLUserChannelBroadcaster*)broadcaster;

- (void)broadcasterDidDeleteContributor:(WLUserChannelBroadcaster*)broadcaster;

@end

@interface WLUserChannelBroadcaster : WLChannelBroadcaster

@end
