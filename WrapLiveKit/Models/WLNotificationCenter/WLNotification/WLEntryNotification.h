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

@property (weak, nonatomic) WLEntry* targetEntry;

@property (strong, nonatomic) Class entryClass;

@property (strong, nonatomic) NSString* entryIdentifier;

@property (strong, nonatomic) NSDictionary* entryData;

@property (strong, nonatomic) NSString* containingEntryIdentifier;

@property (nonatomic) BOOL inserted;

@end

@interface WLEntry (WLNotification)

- (BOOL)notifiableForEvent:(WLEvent)event;

- (void)markAsUnreadIfNeededForEvent:(WLEvent)event;

@end

@interface WLContribution (WLNotification)

@end

@interface WLUser (WLNotification)

@end

@interface WLWrap (WLNotification)

- (BOOL)containsUnreadMessage;

- (NSUInteger)unreadNotificationsMessageCount;

@end

@interface WLComment (WLNotification)

@end