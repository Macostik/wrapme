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
        _identifier = [NSString stringWithFormat:@"%lu_%@_%f", self.type, self.entryIdentifier, self.date.timestamp];
    }
    return _identifier;
}

- (void)setup:(NSDictionary*)data {
    [super setup:data];
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
    
    WLObjectBlock block = ^(id object) {
        if (event == WLEventAdd) {
            switch (weakSelf.type) {
                case WLNotificationCommentAdd: {
                    WLCandy *candy = [(WLComment*)targetEntry candy];
                    if (candy.valid &&
                        !targetEntry.unread &&
                        targetEntry.inserted &&
                        [[candy updatedAt] earlier:[targetEntry updatedAt]]) {
                        candy.commentCount++;
                    }
                    if (targetEntry.notifiable && !targetEntry.unread) targetEntry.unread = YES;
                    break;
                }
                case WLNotificationCandyAdd:
                case WLNotificationMessageAdd:
                    if (!targetEntry.unread && targetEntry.valid) targetEntry.unread = YES;
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
        [[WLEntryManager manager].context processPendingChanges];
        if (success) success();
    };
    
    if (event == WLEventAdd) {
        [targetEntry fetchIfNeeded:block failure:failure];
    } else if (event == WLEventUpdate) {
        block(targetEntry);
    } else if (event == WLEventDelete) {
        block(targetEntry);
    }
}

- (BOOL)playSound {
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdAt >= %@ AND contributor != %@",
                              [NSDate sinceWeekAgo], [WLUser currentUser]];
    NSMutableOrderedSet *contribution = [WLContribution entriesWithPredicate:predicate sorterByKey:@"createdAt"];
    [contribution removeObjectsWhileEnumerating:^BOOL(WLEntry *entry) {
        return [entry isKindOfClass:[WLWrap class]];
    }];
    
    return contribution;
}

- (NSUInteger)unreadNotificationsCount {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdAt >= %@ AND contributor != %@ AND unread == YES",
                              [NSDate sinceWeekAgo], [WLUser currentUser]];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([WLContribution class])];
    request.predicate = predicate;
    request.resultType = NSCountResultType;
    return [[[request execute] lastObject] integerValue];
}

@end

@implementation WLWrap (WLNotification)

- (NSUInteger)unreadNotificationsCandyCount {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdAt >= %@ AND wrap == %@ AND contributor != %@ AND unread == YES",
                              [NSDate dayAgo], self, [WLUser currentUser]];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([WLCandy class])];
    request.predicate = predicate;
    request.resultType = NSCountResultType;
    return [[[request execute] lastObject] integerValue];
}

- (NSUInteger)unreadNotificationsMessageCount {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdAt >= %@ AND wrap == %@ AND contributor != %@ AND unread == YES",
                              [NSDate dayAgo], self, [WLUser currentUser]];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([WLMessage class])];
    request.predicate = predicate;
    request.resultType = NSCountResultType;
    return [[[request execute] lastObject] integerValue];
}

@end

@implementation WLComment (WLNotification)

@end
