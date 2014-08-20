//
//  WLNotificationChannel.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLBlocks.h"

@class PNChannel;
@class WLNotification;

@interface WLNotificationChannel : NSObject

@property (strong, nonatomic) NSString* name;

@property (nonatomic, readonly) BOOL subscribed;

@property (nonatomic) BOOL supportAPNS;

@property (strong, nonatomic) void (^receive) (WLNotification *notification);

+ (instancetype)channel:(NSString*)name;

+ (instancetype)channel:(NSString*)name subscribe:(BOOL)subscribe;

- (void)setName:(NSString *)name subscribe:(BOOL)subscribe;

- (void)subscribe;

- (void)subscribe:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)unsubscribe;

- (void)unsubscribe:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)send:(NSDictionary*)message;

@end
