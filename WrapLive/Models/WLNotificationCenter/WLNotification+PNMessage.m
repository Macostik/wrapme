//
//  WLNotification+PNMessage.m
//  WrapLive
//
//  Created by Sergey Maximenko on 4/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLNotification+PNMessage.h"
#import <PubNub/PNImports.h>

@implementation WLNotification (PNMessage)

+ (instancetype)notificationWithMessage:(PNMessage*)message {
    WLNotification *notification = [self notificationWithData:message.message];
    notification.date = [(message.receiveDate ? : message.date) date];
    return notification;
}

@end
