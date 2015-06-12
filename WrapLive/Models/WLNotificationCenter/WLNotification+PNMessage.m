//
//  WLNotification+PNMessage.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLNotification+PNMessage.h"
#import "PNMessage.h"
#import "PNDate.h"

@implementation WLNotification (PNMessage)

+ (instancetype)notificationWithMessage:(PNMessage*)message {
    WLNotification *notification = [self notificationWithData:(NSDictionary*)message.message];
    notification.date = [(message.receiveDate ? : message.date) date];
    return notification;
}

@end
