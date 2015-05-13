//
//  WLEntryNotification.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryNotification.h"

@implementation WLEntryNotification

+ (BOOL)isSupportedType:(WLNotificationType)type {
    return type != WLNotificationUpdateAvailable;
}

- (NSString *)identifier {
    if (!_identifier.nonempty) {
        _identifier = [NSString stringWithFormat:@"%lu_%@_%f", (unsigned long)self.type, self.entryIdentifier, self.date.timestamp];
    }
    return _identifier;
}

- (void)setup:(NSDictionary*)data {
    [super setup:data];
    self.isSoundAllowed = ([data objectForKey:@"pn_apns"] != nil);
    self.entryData = data;
    WLNotificationType type = self.type;
    
    switch (type) {
        case WLNotificationContributorDelete:
        case WLNotificationCandyDelete:
        case WLNotificationWrapDelete:
        case WLNotificationCommentDelete:
            self.event = WLEventDelete;
            break;
        case WLNotificationContributorAdd:
        case WLNotificationCandyAdd:
        case WLNotificationMessageAdd:
        case WLNotificationCommentAdd:
            self.event = WLEventAdd;
            break;
        case WLNotificationUserUpdate:
        case WLNotificationWrapUpdate:
            self.event = WLEventUpdate;
            break;
        default:
            break;
    }
    
    NSString *dataKey = nil;
    
    switch (type) {
        case WLNotificationContributorAdd:
        case WLNotificationContributorDelete:
        case WLNotificationWrapDelete:
        case WLNotificationWrapUpdate: {
            self.entryClass = [WLWrap class];
            dataKey = WLWrapKey;
        } break;
        case WLNotificationCandyAdd:
        case WLNotificationCandyDelete: {
            self.entryClass = [WLCandy class];
            dataKey = WLCandyKey;
        } break;
        case WLNotificationMessageAdd: {
            self.entryClass = [WLMessage class];
            dataKey = WLMessageKey;
        } break;
        case WLNotificationCommentAdd:
        case WLNotificationCommentDelete: {
            self.entryClass = [WLComment class];
            dataKey = WLCommentKey;
        } break;
        case WLNotificationUserUpdate: {
            self.entryClass = [WLUser class];
            dataKey = WLUserKey;
        } break;
        default:
            break;
    }
    
    self.entryData = [data dictionaryForKey:dataKey];
    self.entryIdentifier = [self.entryClass API_identifier:self.entryData ? : data];
    
    switch (type) {
        case WLNotificationCandyAdd:
        case WLNotificationCandyDelete:
        case WLNotificationMessageAdd: {
            self.containingEntryIdentifier = [data stringForKey:WLWrapUIDKey];
        } break;
        case WLNotificationCommentAdd:
        case WLNotificationCommentDelete: {
            self.containingEntryIdentifier = [data stringForKey:WLCandyUIDKey];
        } break;
        default:
            break;
    }
}

- (WLEntry *)targetEntry {
    if (!_targetEntry) {
        NSDictionary *dictionary = self.entryData;
        WLNotificationType type = self.type;
        WLEntry *targetEntry = nil;
        
        switch (type) {
            case WLNotificationContributorAdd:
            case WLNotificationContributorDelete:
            case WLNotificationWrapDelete:
            case WLNotificationWrapUpdate: {
                targetEntry = dictionary ? [WLWrap API_entry:dictionary] : [WLWrap entry:self.entryIdentifier];
            } break;
            case WLNotificationCandyAdd:
            case WLNotificationCandyDelete: {
                targetEntry = dictionary ? [WLCandy API_entry:dictionary] : [WLCandy entry:self.entryIdentifier];
            } break;
            case WLNotificationMessageAdd: {
                targetEntry = dictionary ? [WLMessage API_entry:dictionary] : [WLMessage entry:self.entryIdentifier];
            } break;
            case WLNotificationCommentAdd:
            case WLNotificationCommentDelete: {
                targetEntry = dictionary ? [WLComment API_entry:dictionary] : [WLComment entry:self.entryIdentifier];
            } break;
            case WLNotificationUserUpdate: {
                if (dictionary) {
                    [[WLAuthorization currentAuthorization] updateWithUserData:dictionary];
                    targetEntry = [WLUser API_entry:dictionary];
                } else {
                    targetEntry = [WLUser entry:self.entryIdentifier];
                }
            } break;
            default:
                break;
        }
        
        if (targetEntry.containingEntry == nil) {
            switch (type) {
                case WLNotificationCandyAdd:
                case WLNotificationCandyDelete:
                case WLNotificationMessageAdd: {
                    targetEntry.containingEntry = [WLWrap entry:self.containingEntryIdentifier];
                } break;
                case WLNotificationCommentAdd:
                case WLNotificationCommentDelete: {
                    targetEntry.containingEntry = [WLCandy entry:self.containingEntryIdentifier];
                } break;
                default:
                    break;
            }
        }
        
        _targetEntry = targetEntry;
    }
    return _targetEntry;
}

- (void)fetch:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak __typeof(self)weakSelf = self;
    WLEntry* targetEntry = [weakSelf targetEntry];
    
    if (!targetEntry.valid) {
        if (success) success();
        return;
    }
    
    if (!targetEntry.valid) {
        if (success) success();
        return;
    }
    
    WLEvent event = self.event;
    
    WLBlock block = ^ {
        if (event == WLEventAdd) {
            switch (weakSelf.type) {
                case WLNotificationCommentAdd: {
                    WLCandy *candy = [(WLComment*)targetEntry candy];
                    if (candy.valid) candy.commentCount = candy.comments.count;
                    if (targetEntry.notifiable) [targetEntry markAsUnread];
                    break;
                }
                case WLNotificationCandyAdd:
                case WLNotificationMessageAdd:
                    [targetEntry markAsUnread];
                    break;
                default:
                    break;
            }
            [targetEntry notifyOnAddition];
        } else if (event == WLEventUpdate) {
            [targetEntry notifyOnUpdate];
        } else if (event == WLEventDelete) {
            [targetEntry remove];
        }
        [[WLEntryManager manager] instantSave];
        if (success) success();
    };
    
    if (event == WLEventAdd) {
        [targetEntry recursivelyFetchIfNeeded:block failure:failure];
    } else if (event == WLEventUpdate) {
        block();
    } else if (event == WLEventDelete) {
        block();
    }
}

- (BOOL)playSound {
    if (!self.isSoundAllowed) {
        return NO;
    }
    WLNotificationType type = self.type;
    switch (type) {
        case WLNotificationContributorAdd:
        case WLNotificationMessageAdd:
        case WLNotificationCommentAdd:
            return self.targetEntry.notifiable;
            break;
        default:
            return NO;
            break;
    }
}
- (NSString *)description {
    return [NSString stringWithFormat:@"%i : %@", (int)self.type, self.entryIdentifier];
}

@end

@implementation WLEntry (WLNotification)

- (NSMutableOrderedSet *)notifications {
    return nil;
}

- (NSUInteger)unreadNotificationsCount {
    return 0;
}

- (BOOL)notifiable {
    return NO;
}

@end

@implementation WLContribution (WLNotification)

- (BOOL)notifiable {
    return !self.contributedByCurrentUser;
}

@end

@implementation WLUser (WLNotification)

- (NSMutableOrderedSet *)notifications {
    NSMutableOrderedSet *contributions = [NSMutableOrderedSet orderedSet];
    NSDate *dayAgo = [NSDate dayAgo];
    WLUser *currentUser = [WLUser currentUser];
    [contributions unionOrderedSet:[WLComment entriesWhere:@"createdAt >= %@ AND contributor != %@", dayAgo, currentUser]];
    [contributions unionOrderedSet:[WLCandy entriesWhere:@"createdAt >= %@ AND contributor != %@", dayAgo, currentUser]];
    [contributions sortByCreatedAt];
    return contributions;
}

- (NSUInteger)unreadNotificationsCount {
    NSMutableOrderedSet *contributions = [WLContribution entriesWhere:@"createdAt >= %@ AND contributor != %@ AND unread == YES", [NSDate dayAgo], [WLUser currentUser]];
    [contributions removeObjectsWhileEnumerating:^BOOL(WLEntry *entry) {
        return [entry isKindOfClass:[WLMessage class]];
    }];
    return contributions.count;
}

@end

@implementation WLWrap (WLNotification)

- (NSUInteger)unreadNotificationsCandyCount {
    return [[WLCandy entriesWhere:@"createdAt >= %@ AND wrap == %@ AND contributor != %@ AND unread == YES",
             [NSDate dayAgo], self, [WLUser currentUser]] count];
}

- (NSUInteger)unreadNotificationsMessageCount {
    return [[WLMessage entriesWhere:@"createdAt >= %@ AND wrap == %@ AND contributor != %@ AND unread == YES",
             [NSDate dayAgo], self, [WLUser currentUser]] count];
}

- (NSUInteger)unreadNotificationsCommentCount {
    return [[WLComment entriesWhere:@"createdAt >= %@ AND candy.wrap == %@ AND contributor != %@ AND unread == YES",
             [NSDate dayAgo], self, [WLUser currentUser]] count];
}

@end

@implementation WLComment (WLNotification)

@end
