//
//  WLNotification+Extanded.h
//  
//
//  Created by Yura Granchenko on 9/2/14.
//
//

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

#import "WLNotification.h"

@interface WLNotification (Extanded)

+ (instancetype)notificationWithMessage:(PNMessage*)message;

+ (instancetype)notificationWithData:(NSDictionary *)data;

- (BOOL)deletion;

- (void)fetch:(void (^)(void))completion;

- (WLUser *)user;

- (NSString *)text;

- (NSDate *)date;

@end
