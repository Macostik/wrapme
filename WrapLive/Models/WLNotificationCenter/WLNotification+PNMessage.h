//
//  WLNotification+PNMessage.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WrapLiveKit.h>

@class PNMessage;

@interface WLNotification (PNMessage)

+ (instancetype)notificationWithMessage:(PNMessage*)message;

@end
