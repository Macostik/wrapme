//
//  WLEntryNotification.h
//  wrapLive
//
//  Created by Sergey Maximenko on 4/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WrapLiveKit.h>
#import "WLEntryManager.h"

typedef NS_ENUM(NSUInteger, WLEvent) {
    WLEventAdd,
    WLEventUpdate,
    WLEventDelete
};

@interface WLEntryNotification : WLNotification

@property (nonatomic) WLEvent event;

@property (weak, nonatomic) WLEntry* targetEntry;

@property (strong, nonatomic) Class entryClass;

@property (strong, nonatomic) NSString* entryIdentifier;

@property (strong, nonatomic) NSDictionary* entryData;

@property (strong, nonatomic) NSString* containingEntryIdentifier;

@end

@interface WLEntry (WLNotification)

@property (nonatomic, readonly) BOOL notifiable;

- (NSMutableOrderedSet*)notifications;

- (NSUInteger)unreadNotificationsCount;

@end

@interface WLContribution (WLNotification)

@end

@interface WLUser (WLNotification)

@end

@interface WLWrap (WLNotification)

- (NSUInteger)unreadNotificationsCandyCount;

- (NSUInteger)unreadNotificationsMessageCount;

- (NSUInteger)unreadNotificationsCommentCount;

@end

@interface WLComment (WLNotification)

@end