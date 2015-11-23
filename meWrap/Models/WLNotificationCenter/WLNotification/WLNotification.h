//
//  WLNotification.h
//  meWrap
//
//  Created by Ravenpod on 19.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
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
    WLNotificationUpdateAvailable       = 1100,
    WLNotificationCandyUpdate           = 1200,
    WLNotificationEngagement            = 99
};

@interface WLNotification : NSObject {
    @protected
    NSString *_identifier;
}

@property (strong, nonatomic) NSString* identifier;

@property (nonatomic) WLNotificationType type;

@property (nonatomic) BOOL containsEntry;

@property (readonly, nonatomic) BOOL playSound;

@property (nonatomic) BOOL isSoundAllowed;

@property (strong, nonatomic) NSDate* date;

@property (strong, nonatomic) NSDate *publishedAt;

@property (readonly, nonatomic) BOOL presentable;

@property (strong, nonatomic) NSDictionary *data;

@property (nonatomic) WLEvent event;

@property (strong, nonatomic) Entry *entry;

@property (strong, nonatomic) User *requester;

@property (strong, nonatomic) EntryDescriptor* descriptor;

@property (nonatomic) BOOL trimmed;

@property (nonatomic) BOOL inserted;

@property (nonatomic) BOOL originatedByCurrentUser;

+ (instancetype)notificationWithMessage:(id)message;

+ (instancetype)notificationWithData:(NSDictionary*)data;

- (void)createTargetEntry;

- (void)prepare;

- (void)fetch:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)finalize;

- (void)handle:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)setup:(NSDictionary*)data;

@end

@interface Entry (WLNotification)

- (BOOL)notifiableForNotification:(WLNotification*)notification;

- (void)markAsUnreadIfNeededForNotification:(WLNotification*)notification;

- (void)prepareForAddNotification:(WLNotification *)notification;

- (void)prepareForUpdateNotification:(WLNotification *)notification;

- (void)prepareForDeleteNotification:(WLNotification *)notification;

- (void)fetchAddNotification:(WLNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)fetchUpdateNotification:(WLNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)fetchDeleteNotification:(WLNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)finalizeAddNotification:(WLNotification *)notification;

- (void)finalizeUpdateNotification:(WLNotification *)notification;

- (void)finalizeDeleteNotification:(WLNotification *)notification;

@end

@interface Contribution (WLNotification)

@end

@interface User (WLNotification) @end

@interface Wrap (WLNotification) @end

@interface Candy (WLNotification) @end

@interface Message (WLNotification) @end

@interface Comment (WLNotification) @end

