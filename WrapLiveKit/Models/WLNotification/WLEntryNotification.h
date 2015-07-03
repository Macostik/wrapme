//
//  WLEntryNotification.h
//  wrapLive
//
//  Created by Sergey Maximenko on 4/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WrapLiveKit.h>
#import "WLEntryManager.h"
#import "WLCommonEnums.h"

@interface WLEntryNotification : WLNotification

@property (nonatomic) WLEvent event;

@property (strong, nonatomic) WLEntry* targetEntry;

@property (strong, nonatomic) Class entryClass;

@property (strong, nonatomic) NSString* entryIdentifier;

@property (strong, nonatomic) NSDictionary* entryData;

@property (strong, nonatomic) NSString* containingEntryIdentifier;

@property (nonatomic) BOOL inserted;

- (void)createTargetEntry;

@end

@interface WLEntry (WLNotification)

- (BOOL)notifiableForEvent:(WLEvent)event;

- (void)markAsUnreadIfNeededForEvent:(WLEvent)event;

- (void)prepareForAddNotification:(WLEntryNotification *)notification;

- (void)prepareForUpdateNotification:(WLEntryNotification *)notification;

- (void)prepareForDeleteNotification:(WLEntryNotification *)notification;

- (void)fetchAddNotification:(WLEntryNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)fetchUpdateNotification:(WLEntryNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)fetchDeleteNotification:(WLEntryNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)finalizeAddNotification:(WLEntryNotification *)notification;

- (void)finalizeUpdateNotification:(WLEntryNotification *)notification;

- (void)finalizeDeleteNotification:(WLEntryNotification *)notification;

@end

@interface WLContribution (WLNotification)

@end

@interface WLUser (WLNotification)

@end

@interface WLWrap (WLNotification)

- (BOOL)containsUnreadMessage;

- (NSUInteger)unreadNotificationsMessageCount;

@end

@interface WLCandy (WLNotification)

@end

@interface WLMessage (WLNotification)

@end

@interface WLComment (WLNotification)

@end