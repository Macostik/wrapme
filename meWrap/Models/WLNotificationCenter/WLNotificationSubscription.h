//
//  WLNotificationChannel.h
//  meWrap
//
//  Created by Ravenpod on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PubNub.h"

@class WLNotificationSubscription;

@protocol WLNotificationSubscriptionDelegate <NSObject>

@optional
- (void)notificationSubscription:(WLNotificationSubscription*)subscription didReceiveMessage:(PNMessageData*)message;

- (void)notificationSubscription:(WLNotificationSubscription*)subscription didReceivePresenceEvent:(PNPresenceEventData*)event;

@end

@interface WLNotificationSubscription : NSObject

@property (strong, nonatomic) NSString* name;

@property (nonatomic, readonly) BOOL subscribed;

@property (nonatomic, weak) id <WLNotificationSubscriptionDelegate> delegate;

+ (instancetype)subscription:(NSString *)name;

+ (instancetype)subscription:(NSString *)name presence:(BOOL)presence;

+ (instancetype)subscription:(NSString *)name presence:(BOOL)presence group:(BOOL)group;

- (void)subscribe;

- (void)unsubscribe;

- (void)send:(NSDictionary*)message;

- (void)changeState:(NSDictionary*)state;

- (void)hereNow:(WLArrayBlock)completion;

- (void)history:(NSDate*)from to:(NSDate*)to success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (void)didReceiveMessage:(PNMessageData*)message;

- (void)didReceivePresenceEvent:(PNPresenceEventData*)event;

@end
