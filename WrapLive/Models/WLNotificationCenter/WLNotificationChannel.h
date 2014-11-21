//
//  WLNotificationChannel.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLNotificationChannel : NSObject

@property (strong, nonatomic) PNChannel* channel;

@property (nonatomic, readonly) BOOL subscribed;

@property (strong, nonatomic) PubNubMessageBlock messageHandler;

@property (strong, nonatomic) PNClientPresenceEventHandlingBlock presenseEventHandler;

+ (instancetype)channelWithName:(NSString *)channelName;

+ (instancetype)channelWithName:(NSString *)channelName shouldObservePresence:(BOOL)observePresence;

- (void)subscribe;

- (void)unsubscribe;

- (void)send:(NSDictionary*)message;

- (void)changeState:(NSDictionary*)state;

- (void)participants:(WLArrayBlock)completion;

- (void)enableAPNS;

- (void)observePresense:(PNClientPresenceEventHandlingBlock)presenseEventHandler;

- (void)observeMessages:(PubNubMessageBlock)messageHandler;

- (void)removeObserving;

@end
