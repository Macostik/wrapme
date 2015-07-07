//
//  WLNotification+PNMessage.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLNotification+PNMessage.h"
#import "PubNub.h"
#import "NSDate+PNTimetoken.h"

@implementation WLNotification (PNMessage)

+ (instancetype)notificationWithMessage:(id)message {
    if ([message isKindOfClass:[PNMessageData class]]) {
        WLNotification *notification = [self notificationWithData:[(PNMessageData*)message message]];
        notification.date = [NSDate dateWithTimetoken:[(PNMessageData*)message timetoken]];
        return notification;
    } else if ([message isKindOfClass:[NSDictionary class]]) {
        WLNotification *notification = [self notificationWithData:[(NSDictionary*)message objectForKey:@"message"]];
        notification.date = [NSDate dateWithTimetoken:[(NSDictionary*)message numberForKey:@"timetoken"]];
        return notification;
    }
    return nil;
}

@end
