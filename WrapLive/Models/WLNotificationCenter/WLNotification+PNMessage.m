//
//  WLNotification+PNMessage.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLNotification+PNMessage.h"
#import "PubNub.h"

@implementation WLNotification (PNMessage)

+ (instancetype)notificationWithMessage:(id)message {
    if ([message isKindOfClass:[PNMessageData class]]) {
        WLNotification *notification = [self notificationWithData:[(PNMessageData*)message message]];
        notification.date = [NSDate dateWithTimeIntervalSince1970:[[(PNMessageData*)message timetoken] doubleValue] / 10000000.0f];
        return notification;
    } else if ([message isKindOfClass:[NSDictionary class]]) {
        WLNotification *notification = [self notificationWithData:[(NSDictionary*)message objectForKey:@"message"]];
        notification.date = [NSDate dateWithTimeIntervalSince1970:[(NSDictionary*)message doubleForKey:@"timetoken"] / 10000000.0f];
        return notification;
    }
    return nil;
}

@end
