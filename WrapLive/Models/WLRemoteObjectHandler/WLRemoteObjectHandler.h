//
//  WLRemoteObjectHandler.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLBroadcaster.h"
#import "WLNotification.h"

@interface WLRemoteObjectHandler : NSObject

@property (assign, nonatomic) BOOL isLoaded;

+ (instancetype)sharedObject;

- (void)handleRemoteObject:(WLEntry*)object;

@end

@interface WLNotification (WLRemoteObjectHandler)

- (void)handleRemoteObject;

@end

@interface NSURL (WLRemoteObjectHandler)

- (void)handleRemoteObject;

@end
