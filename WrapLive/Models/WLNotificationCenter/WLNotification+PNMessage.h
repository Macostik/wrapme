//
//  WLNotification+PNMessage.h
//  WrapLive
//
//  Created by Sergey Maximenko on 4/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLNotification.h"

@class PNMessage;

@interface WLNotification (PNMessage)

+ (instancetype)notificationWithMessage:(PNMessage*)message;

@end
