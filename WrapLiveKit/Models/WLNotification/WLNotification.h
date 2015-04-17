//
//  WLNotification.h
//  WrapLive
//
//  Created by Sergey Maximenko on 19.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WLNotificationType) {
	WLNotificationContributorAdd        = 100,
	WLNotificationContributorDelete     = 200,
	WLNotificationCandyAdd              = 300,
	WLNotificationCandyDelete           = 400,
	WLNotificationCommentAdd            = 500,
	WLNotificationCommentDelete         = 600,
	WLNotificationMessageAdd            = 700,
	WLNotificationWrapDelete            = 800,
    WLNotificationUserUpdate            = 900,
    WLNotificationWrapUpdate            = 1000,
    WLNotificationUpdateAvailable       = 1100
};

@interface WLNotification : NSObject {
    @protected
    NSString *_identifier;
}

@property (strong, nonatomic) NSString* identifier;

@property (nonatomic) WLNotificationType type;

@property (readonly, nonatomic) BOOL playSound;

@property (nonatomic) BOOL isSoundAllowed;

@property (strong, nonatomic) NSDate* date;

@property (strong, nonatomic) NSDate *publishedAt;

+ (instancetype)notificationWithData:(NSDictionary*)data;

+ (NSMutableOrderedSet*)notificationsWithDataArray:(NSArray*)array;

+ (BOOL)isSupportedType:(WLNotificationType)type;

- (void)fetch:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)setup:(NSDictionary*)data;

@end

