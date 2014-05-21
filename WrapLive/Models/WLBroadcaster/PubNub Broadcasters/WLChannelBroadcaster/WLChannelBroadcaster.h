//
//  WLChannelBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 14.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLNotificationBroadcaster.h"
#import "WLNotification.h"

@interface WLChannelBroadcaster : WLBroadcaster <WLNotificationReceiver>

@end
