//
//  WLNotification.h
//  WrapLive
//
//  Created by Sergey Maximenko on 19.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLEntryManager.h"

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
    WLNotificationWrapUpdate            = 1000
};

typedef NS_ENUM(NSUInteger, WLEvent) {
	WLEventAdd,
    WLEventUpdate,
    WLEventDelete
};

@interface WLNotification : NSObject

@property (nonatomic) WLNotificationType type;

@property (nonatomic) WLEvent event;

@property (strong, nonatomic) WLEntry* targetEntry;

@property (readonly, nonatomic) BOOL playSound;

+ (instancetype)notificationWithMessage:(PNMessage*)message;

+ (instancetype)notificationWithData:(NSDictionary*)data;

+ (NSMutableOrderedSet*)notificationsWithDataArray:(NSArray*)array;

- (void)fetch:(WLBlock)completion;

@end

@interface WLEntry (WLNotification)

@property (nonatomic, readonly) BOOL notifiable;

@end

@interface WLComment (WLNotification) @end

