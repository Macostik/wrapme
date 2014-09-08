//
//  WLNotification.h
//  WrapLive
//
//  Created by Sergey Maximenko on 19.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLWrap;
@class WLCandy;
@class WLComment;
@class WLUser;

typedef NS_ENUM(NSUInteger, WLNotificationType) {
	WLNotificationContributorAddition  = 100,
	WLNotificationContributorDeletion  = 200,
	WLNotificationImageCandyAddition   = 300,
	WLNotificationImageCandyDeletion   = 400,
	WLNotificationCandyCommentAddition = 500,
	WLNotificationCandyCommentDeletion = 600,
	WLNotificationChatCandyAddition    = 700,
	WLNotificationWrapDeletion         = 800,
    WLNotificationBeginTyping          = 2000,
    WLNotificationEndTyping            = 2001,
};

@interface WLNotification : NSObject

@property (nonatomic) WLNotificationType type;

@property (strong, nonatomic) NSDictionary* data;

@property (strong, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) WLCandy* candy;

@property (strong, nonatomic) WLComment* comment;

@property (strong, nonatomic) NSString *text;

@property (strong, nonatomic) WLUser *user;

@property (strong, nonatomic) NSDate *date;

+ (instancetype)notificationWithMessage:(PNMessage*)message;

+ (instancetype)notificationWithData:(NSDictionary*)data;

+ (NSMutableOrderedSet*)notificationsWithDataArray:(NSArray*)array;

- (BOOL)deletion;

- (void)fetch:(void (^)(void))completion;

@end

