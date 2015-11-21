//
//  WLNotification.m
//  meWrap
//
//  Created by Ravenpod on 19.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotification.h"
#import "PubNub+SharedInstance.h"
#import "NSDate+PNTimetoken.h"
#import "WLCommonEnums.h"

@interface WLNotification ()

@end

@implementation WLNotification

@synthesize identifier = _identifier;

- (NSString *)identifier {
    if (!_identifier.nonempty) {
        _identifier = [NSString stringWithFormat:@"%lu_%@_%f", (unsigned long)self.type, self.descriptor.identifier, self.date.timestamp];
    }
    return _identifier;
}

+ (instancetype)notificationWithMessage:(id)message {
    if ([message isKindOfClass:[PNMessageData class]]) {
        WLNotification *notification = [self notificationWithData:[(PNMessageData*)message message]];
        notification.date = [NSDate dateWithTimetoken:[(PNMessageData*)message timetoken]];
        return notification;
    } else if ([message isKindOfClass:[NSDictionary class]]) {
        WLNotification *notification = [self notificationWithData:[(NSDictionary*)message objectForKey:@"message"]];
        notification.date = [NSDate dateWithTimetoken:[(NSDictionary*)message numberForKey:@"timetoken"]];
        return notification;
    }
    return nil;
}

+ (instancetype)notificationWithData:(NSDictionary *)data {
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSString* typeString = [data objectForKey:@"msg_type"];
        if (typeString) {
            WLNotificationType type = [typeString integerValue];
            WLNotification* notification = [[self alloc] init];
            notification.type = type;
            [notification setup:data];
            return notification;
        }
    }
    return nil;
}

- (void)setup:(NSDictionary*)data {
    self.data = data;
    self.identifier = [data stringForKey:@"msg_uid"];
    self.publishedAt = [data dateForKey:@"msg_published_at"];
    
    NSDictionary *originator = [data dictionaryForKey:@"originator"];
    if (originator) {
        self.originatedByCurrentUser = [originator[WLUserUIDKey] isEqualToString:[User currentUser].identifier] && [originator[WLDeviceIDKey] isEqualToString:[Authorization currentAuthorization].deviceUID];
    }
    
    WLNotificationType type = self.type;
    
    if (type == WLNotificationUpdateAvailable) {
        self.containsEntry = NO;
        return;
    }
    
    self.containsEntry = YES;
    
    self.isSoundAllowed = ([data objectForKey:@"pn_apns"] != nil);
    
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
        case WLNotificationCandyUpdate:
            self.event = WLEventUpdate;
            break;
        default:
            break;
    }
    
    WLEntryDescriptor *descriptor = [[WLEntryDescriptor alloc] init];
    NSDictionary *entryData = nil;
    switch (type) {
        case WLNotificationContributorAdd:
        case WLNotificationContributorDelete:
        case WLNotificationWrapDelete:
        case WLNotificationWrapUpdate: {
            descriptor.entityName = [Wrap entityName];
            entryData = [data dictionaryForKey:WLWrapKey];
            descriptor.identifier = [Wrap uid:entryData ? : data];
            descriptor.uploadIdentifier = [Wrap locuid:entryData ? : data];
        } break;
        case WLNotificationCandyAdd:
        case WLNotificationCandyDelete:
        case WLNotificationCandyUpdate:{
            descriptor.entityName = [Candy entityName];
            entryData = [data dictionaryForKey:WLCandyKey];
            descriptor.identifier = [Candy uid:entryData ? : data];
            descriptor.uploadIdentifier = [Candy locuid:entryData ? : data];
        } break;
        case WLNotificationMessageAdd: {
            descriptor.entityName = [Message entityName];
            entryData = [data dictionaryForKey:WLMessageKey];
            descriptor.identifier = [Message uid:entryData ? : data];
            descriptor.uploadIdentifier = [Message locuid:entryData ? : data];
        } break;
        case WLNotificationCommentAdd:
        case WLNotificationCommentDelete: {
            descriptor.entityName = [Comment entityName];
            entryData = [data dictionaryForKey:WLCommentKey];
            descriptor.identifier = [Comment uid:entryData ? : data];
            descriptor.uploadIdentifier = [Comment locuid:entryData ? : data];
        } break;
        case WLNotificationUserUpdate: {
            descriptor.entityName = [User entityName];
            entryData = [data dictionaryForKey:WLUserKey];
            descriptor.identifier = [User uid:entryData ? : data];
            descriptor.uploadIdentifier = [User locuid:entryData ? : data];
        } break;
        default:
            break;
    }
    descriptor.data = entryData;
    self.trimmed = entryData == nil;
    
    switch (type) {
        case WLNotificationCandyAdd:
        case WLNotificationCandyDelete:
        case WLNotificationMessageAdd: {
            descriptor.container = [data stringForKey:WLWrapUIDKey];
        } break;
        case WLNotificationCommentAdd:
        case WLNotificationCommentDelete: {
            descriptor.container = [data stringForKey:WLCandyUIDKey];
        } break;
        default:
            break;
    }
    
    if (descriptor.identifier.nonempty) {
        self.descriptor = descriptor;
    }
}

- (Entry *)entry {
    if (!_entry) {
        [self createTargetEntry];
    }
    return _entry.valid ? _entry : nil;
}

- (void)createTargetEntry {
    if (!self.containsEntry) {
        return;
    }
    
    if (self.event == WLEventDelete && ![self.descriptor entryExists]) {
        return;
    }
    
    WLEntryDescriptor *descriptor = self.descriptor;
    NSDictionary *dictionary = descriptor.data;
    WLNotificationType type = self.type;
    Entry *entry = [[EntryContext sharedContext] entry:descriptor.entityName uid:descriptor.identifier locuid:descriptor.uploadIdentifier];
    if (dictionary) {
        if (type == WLNotificationUserUpdate) {
            [[Authorization currentAuthorization] updateWithUserData:dictionary];
        }
        if (type == WLNotificationCandyAdd && self.originatedByCurrentUser) {
            Asset* oldPicture = [entry.picture copy];
            [entry map:dictionary];
            [oldPicture cacheForAsset:entry.picture];
        } else {
            [entry map:dictionary];
        }
    }
    
    self.inserted = entry.inserted;
    
    if (entry && entry.container == nil) {
        switch (type) {
            case WLNotificationCandyAdd:
            case WLNotificationCandyDelete:
            case WLNotificationMessageAdd:
            case WLNotificationCommentAdd:
            case WLNotificationCommentDelete: {
                entry.container = [[EntryContext sharedContext] entry:[[entry class] containerEntityName] uid:descriptor.entityName];
            } break;
            default:
                break;
        }
    }
    
    _entry = entry;
}

- (void)prepare {
    WLEvent event = self.event;
    
    Entry *entry = [self entry];
    
    if (!entry) {
        return;
    }
    
    if (event == WLEventAdd) {
        [entry prepareForAddNotification:self];
    } else if (event == WLEventUpdate) {
        [entry prepareForUpdateNotification:self];
    } else if (event == WLEventDelete) {
        [entry prepareForDeleteNotification:self];
    }
}

- (void)fetch:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak __typeof(self)weakSelf = self;
    
    WLEvent event = self.event;
    
    if (!self.containsEntry) {
        if (success) success();
        return;
    }
    
    Entry* entry = [weakSelf entry];
    
    if (!entry) {
        if (success) success();
        return;
    }
    
    if (event == WLEventAdd) {
        [entry fetchAddNotification:self success:success failure:failure];
    } else if (event == WLEventUpdate) {
        [entry fetchUpdateNotification:self success:success failure:failure];
    } else if (event == WLEventDelete) {
        [entry fetchDeleteNotification:self success:success failure:failure];
    }
}

- (void)finalize {
    WLEvent event = self.event;
    
    Entry *entry = [self entry];
    
    if (!entry) {
        return;
    }
    
    if (event == WLEventAdd) {
        [entry finalizeAddNotification:self];
    } else if (event == WLEventUpdate) {
        [entry finalizeUpdateNotification:self];
    } else if (event == WLEventDelete) {
        [entry finalizeDeleteNotification:self];
    }
}

- (void)handle:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak __typeof(self)weakSelf = self;
    [self prepare];
    [self fetch:^{
        [weakSelf finalize];
        if (success) success();
    } failure:failure];
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
            return [self.entry notifiableForNotification:self];
            break;
        default:
            return NO;
            break;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%i : %@", (int)self.type, self.descriptor.identifier];
}

- (BOOL)presentable {
    return self.event != WLEventDelete;
}

@end

@implementation Entry (WLNotification)

- (BOOL)notifiableForNotification:(WLNotification*)notification {
    return NO;
}

- (void)markAsUnreadIfNeededForNotification:(WLNotification*)notification {
    if ([self notifiableForNotification:notification]) [self markAsUnread];
}

- (void)prepareForAddNotification:(WLNotification *)notification {
    
}

- (void)prepareForUpdateNotification:(WLNotification *)notification {
    
}

- (void)prepareForDeleteNotification:(WLNotification *)notification {
    
}

- (void)fetchAddNotification:(WLNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    [self recursivelyFetchIfNeeded:success failure:failure];
}

- (void)fetchUpdateNotification:(WLNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    if (notification.trimmed) {
        [self fetch:^(id object) {
            if (success) success();
        } failure:failure];
    } else {
        if (success) success();
    }
}

- (void)fetchDeleteNotification:(WLNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    if (success) success();
}

- (void)finalizeAddNotification:(WLNotification *)notification {
    [self notifyOnAddition];
}

- (void)finalizeUpdateNotification:(WLNotification *)notification {
    [self notifyOnUpdate:EntryUpdateEventDefault];
}

- (void)finalizeDeleteNotification:(WLNotification *)notification {
    [self remove];
}

@end

@implementation Contribution (WLNotification)

- (BOOL)notifiableForNotification:(WLNotification*)notification {
    WLEvent event = notification.event;
    if (event == WLEventAdd) {
        return !self.contributor.current;
    } else if (event == WLEventUpdate) {
        return ![self.editor current];
    }
    return NO;
}

@end

@implementation User (WLNotification)

@end

@implementation Wrap (WLNotification)

- (BOOL)notifiableForNotification:(WLNotification *)notification {
    if (notification.event == WLEventAdd) {
        NSString *userIdentifier = notification.data[WLUserUIDKey] ? : notification.data[WLUserKey][WLUserUIDKey];
        return !self.contributor.current && [userIdentifier isEqualToString:[User currentUser].identifier] && notification.requester != [User currentUser];
    } else {
        return [super notifiableForNotification:notification];
    }
}

- (void)fetchAddNotification:(WLNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    NSString *userIdentifier = notification.data[WLUserUIDKey];
    NSDictionary *userData = notification.data[WLUserKey];
    User *user = userData ? [User mappedEntry:userData] : [User entry:userIdentifier];
    if (user && ![self.contributors containsObject:user]) {
        [[self mutableContributors] addObject:user];
    }
    NSDictionary *inviter = notification.data[@"inviter"];
    if (inviter) {
        notification.requester = [User mappedEntry:inviter];
    }
    [super fetchAddNotification:notification success:success failure:failure];
}

- (void)finalizeAddNotification:(WLNotification *)notification {
    if (self.isPublic && !notification.inserted) {
        [self notifyOnUpdate:EntryUpdateEventContributorsChanged];
    } else {
        [self notifyOnAddition];
    }
}

- (void)finalizeDeleteNotification:(WLNotification *)notification {
    NSString *userIdentifier = notification.data[WLUserUIDKey];
    NSDictionary *userData = notification.data[WLUserKey];
    User *user = userData ? [User mappedEntry:userData] : [User entry:userIdentifier];
    if (user) {
        if (notification.type == WLNotificationWrapDelete || (user.current && !self.isPublic)) {
            [super finalizeDeleteNotification:notification];
        } else {
            [[self mutableContributors] removeObject:user];
            [self notifyOnUpdate:EntryUpdateEventContributorsChanged];
        }
    }
}

@end

@implementation Candy (WLNotification)

- (void)fetchAddNotification:(WLNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [super fetchAddNotification:notification success:^{
        [weakSelf.picture fetch:success];
    } failure:failure];
}

- (void)fetchUpdateNotification:(WLNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [super fetchUpdateNotification:notification success:^{
        [weakSelf.picture fetch:success];
    } failure:failure];
}

- (void)finalizeAddNotification:(WLNotification *)notification {
    if (notification.inserted) [self markAsUnreadIfNeededForNotification:notification];
    [super finalizeAddNotification:notification];
}

- (void)finalizeUpdateNotification:(WLNotification *)notification {
    [self markAsUnreadIfNeededForNotification:notification];
    [super finalizeUpdateNotification:notification];
}

- (void)finalizeDeleteNotification:(WLNotification *)notification {
    Wrap *wrap = self.wrap;
    [super finalizeDeleteNotification:notification];
    if (wrap.valid && !wrap.candies.nonempty) {
        [wrap fetch:nil success:nil failure:nil];
    }
}

@end

@implementation Message (WLNotification)

- (void)finalizeAddNotification:(WLNotification *)notification {
    if (notification.inserted) [self markAsUnreadIfNeededForNotification:notification];
    [super finalizeAddNotification:notification];
}

@end

@implementation Comment (WLNotification)

- (void)finalizeAddNotification:(WLNotification *)notification {
    Candy *candy = self.candy;
    if (candy.valid) candy.commentCount = candy.comments.count;
    if (notification.inserted) [self markAsUnreadIfNeededForNotification:notification];
    [super finalizeAddNotification:notification];
}

- (BOOL)notifiableForNotification:(WLNotification*)notification {
    if (notification.event != WLEventAdd) {
        return [super notifiableForNotification:notification];
    }
    
    User *currentUser = [User currentUser];
    
    if (self.contributor == currentUser) {
        return NO;
    }
    Candy *candy = self.candy;
    if (candy.contributor == currentUser) {
        return YES;
    } else {
        for (Comment *comment in candy.comments) {
            if (comment.contributor == currentUser) {
                return YES;
                break;
            }
        }
    }
    return NO;
}

@end
