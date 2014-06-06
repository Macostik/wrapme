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

typedef NS_ENUM(NSUInteger, WLNotificationType) {
	WLNotificationContributorAddition  = 100,
	WLNotificationContributorDeletion  = 200,
	WLNotificationImageCandyAddition   = 300,
	WLNotificationImageCandyDeletion   = 400,
	WLNotificationCandyCommentAddition = 500,
	WLNotificationCandyCommentDeletion = 600,
	WLNotificationChatCandyAddition    = 700,
	WLNotificationWrapDeletion         = 800,
};

@interface WLNotification : NSObject

@property (nonatomic) WLNotificationType type;

@property (strong, nonatomic) NSDictionary* data;

@property (strong, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) WLCandy* candy;

@property (strong, nonatomic) WLComment* comment;

+ (instancetype)notificationWithMessage:(PNMessage*)message;

+ (instancetype)notificationWithData:(NSDictionary*)data;

- (BOOL)deletion;

@end
