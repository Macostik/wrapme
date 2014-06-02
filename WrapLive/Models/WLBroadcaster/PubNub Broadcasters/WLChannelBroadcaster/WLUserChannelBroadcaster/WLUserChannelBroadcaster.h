//
//  WLUserChannelBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 14.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChannelBroadcaster.h"

@class WLUserChannelBroadcaster;
@class WLWrap;

@protocol WLUserChannelBroadcastReceiver <NSObject>

@optional

- (void)broadcaster:(WLUserChannelBroadcaster*)broadcaster didBecomeContributor:(WLWrap*)wrap;

- (void)broadcaster:(WLUserChannelBroadcaster*)broadcaster didResignContributor:(WLWrap*)wrap;

@end

@interface WLUserChannelBroadcaster : WLChannelBroadcaster

@end
