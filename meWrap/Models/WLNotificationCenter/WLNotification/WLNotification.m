//
//  WLNotification.m
//  meWrap
//
//  Created by Ravenpod on 19.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotification.h"

@implementation WLNotification

- (NSString *)uid {
    if (!_uid.nonempty) {
        _uid = [NSString stringWithFormat:@"%lu_%@_%f", (unsigned long)self.type, self.descriptor.uid, self.date.timestamp];
    }
    return _uid;
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
    self.uid = [data stringForKey:@"msg_uid"];
    self.publishedAt = [data dateForKey:@"msg_published_at"];
    
    NSDictionary *originator = [data dictionaryForKey:@"originator"];
    if (originator) {
        NSString *userID = [originator stringForKey:@"user_uid"];
        NSString *deviceID = [originator stringForKey:@"device_uid"];
        self.originatedByCurrentUser = userID.nonempty && deviceID.nonempty && [userID isEqualToString:[User currentUser].uid] && [deviceID isEqualToString:[Authorization currentAuthorization].deviceUID];
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
            self.event = EventDelete;
            break;
        case WLNotificationContributorAdd:
        case WLNotificationCandyAdd:
        case WLNotificationMessageAdd:
        case WLNotificationCommentAdd:
            self.event = EventAdd;
            break;
        case WLNotificationUserUpdate:
        case WLNotificationWrapUpdate:
        case WLNotificationCandyUpdate:
            self.event = EventUpdate;
            break;
        default:
            break;
    }
    
    EntryDescriptor *descriptor = [[EntryDescriptor alloc] init];
    NSDictionary *entryData = nil;
    switch (type) {
        case WLNotificationContributorAdd:
        case WLNotificationContributorDelete:
        case WLNotificationWrapDelete:
        case WLNotificationWrapUpdate: {
            descriptor.name = [Wrap entityName];
            entryData = [data dictionaryForKey:@"wrap"];
            descriptor.uid = [Wrap uid:entryData ? : data];
            descriptor.locuid = [Wrap locuid:entryData ? : data];
        } break;
        case WLNotificationCandyAdd:
        case WLNotificationCandyDelete:
        case WLNotificationCandyUpdate:{
            descriptor.name = [Candy entityName];
            entryData = [data dictionaryForKey:@"candy"];
            descriptor.uid = [Candy uid:entryData ? : data];
            descriptor.locuid = [Candy locuid:entryData ? : data];
        } break;
        case WLNotificationMessageAdd: {
            descriptor.name = [Message entityName];
            entryData = [data dictionaryForKey:@"chat"];
            descriptor.uid = [Message uid:entryData ? : data];
            descriptor.locuid = [Message locuid:entryData ? : data];
        } break;
        case WLNotificationCommentAdd:
        case WLNotificationCommentDelete: {
            descriptor.name = [Comment entityName];
            entryData = [data dictionaryForKey:@"comment"];
            descriptor.uid = [Comment uid:entryData ? : data];
            descriptor.locuid = [Comment locuid:entryData ? : data];
        } break;
        case WLNotificationUserUpdate: {
            descriptor.name = [User entityName];
            entryData = [data dictionaryForKey:@"user"];
            descriptor.uid = [User uid:entryData ? : data];
            descriptor.locuid = [User locuid:entryData ? : data];
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
            descriptor.container = [data stringForKey:@"wrap_uid"];
        } break;
        case WLNotificationCommentAdd:
        case WLNotificationCommentDelete: {
            descriptor.container = [data stringForKey:@"candy_uid"];
        } break;
        default:
            break;
    }
    
    if (descriptor.uid.nonempty) {
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
    
    if (self.event == EventDelete && ![self.descriptor entryExists]) {
        return;
    }
    
    EntryDescriptor *descriptor = self.descriptor;
    NSDictionary *dictionary = descriptor.data;
    WLNotificationType type = self.type;
    Entry *entry = [[EntryContext sharedContext] entry:descriptor.name uid:descriptor.uid locuid:descriptor.locuid];
    if (dictionary) {
        if (type == WLNotificationUserUpdate) {
            [[Authorization currentAuthorization] updateWithUserData:dictionary];
        }
        if (type == WLNotificationCandyAdd && self.originatedByCurrentUser) {
            Asset* oldPicture = [((Candy*)entry).asset copy];
            [entry map:dictionary];
            [oldPicture cacheForAsset:((Candy*)entry).asset];
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
                entry.container = [[EntryContext sharedContext] entry:[[entry class] containerEntityName] uid:descriptor.name];
            } break;
            default:
                break;
        }
    }
    
    _entry = entry;
}

- (void)prepare {
    Event event = self.event;
    
    Entry *entry = [self entry];
    
    if (!entry) {
        return;
    }
    
    if (event == EventAdd) {
        [entry prepareForAddNotification:self];
    } else if (event == EventUpdate) {
        [entry prepareForUpdateNotification:self];
    } else if (event == EventDelete) {
        [entry prepareForDeleteNotification:self];
    }
}

- (void)fetch:(Block)success failure:(FailureBlock)failure {
    __weak __typeof(self)weakSelf = self;
    
    Event event = self.event;
    
    if (!self.containsEntry) {
        if (success) success();
        return;
    }
    
    Entry* entry = [weakSelf entry];
    
    if (!entry) {
        if (success) success();
        return;
    }
    
    if (event == EventAdd) {
        [entry fetchAddNotification:self success:success failure:failure];
    } else if (event == EventUpdate) {
        [entry fetchUpdateNotification:self success:success failure:failure];
    } else if (event == EventDelete) {
        [entry fetchDeleteNotification:self success:success failure:failure];
    }
}

- (void)finalize {
    Event event = self.event;
    
    Entry *entry = [self entry];
    
    if (!entry) {
        return;
    }
    
    if (event == EventAdd) {
        [entry finalizeAddNotification:self];
    } else if (event == EventUpdate) {
        [entry finalizeUpdateNotification:self];
    } else if (event == EventDelete) {
        [entry finalizeDeleteNotification:self];
    }
}

- (void)handle:(Block)success failure:(FailureBlock)failure {
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
    return [NSString stringWithFormat:@"%i : %@", (int)self.type, self.descriptor.uid];
}

- (BOOL)presentable {
    return self.event != EventDelete;
}

@end

@implementation Entry (WLNotification)

- (BOOL)notifiableForNotification:(WLNotification*)notification {
    return NO;
}

- (void)markAsUnreadIfNeededForNotification:(WLNotification*)notification {
    if ([self notifiableForNotification:notification]) [self markAsUnread:YES];
}

- (void)prepareForAddNotification:(WLNotification *)notification {
    
}

- (void)prepareForUpdateNotification:(WLNotification *)notification {
    
}

- (void)prepareForDeleteNotification:(WLNotification *)notification {
    
}

- (void)fetchAddNotification:(WLNotification *)notification success:(Block)success failure:(FailureBlock)failure {
    [self recursivelyFetchIfNeeded:success failure:failure];
}

- (void)fetchUpdateNotification:(WLNotification *)notification success:(Block)success failure:(FailureBlock)failure {
    if (notification.trimmed) {
        [self fetch:^(id object) {
            if (success) success();
        } failure:failure];
    } else {
        if (success) success();
    }
}

- (void)fetchDeleteNotification:(WLNotification *)notification success:(Block)success failure:(FailureBlock)failure {
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
    Event event = notification.event;
    if (event == EventAdd) {
        return !self.contributor.current;
    } else if (event == EventUpdate) {
        return ![self.editor current];
    }
    return NO;
}

@end

@implementation User (WLNotification)

@end

@implementation Wrap (WLNotification)

- (BOOL)notifiableForNotification:(WLNotification *)notification {
    if (notification.event == EventAdd) {
        NSString *userIdentifier = notification.data[@"user_uid"] ? : notification.data[@"user"][@"user_uid"];
        return !self.contributor.current && [userIdentifier isEqualToString:[User currentUser].uid] && notification.requester != [User currentUser];
    } else {
        return [super notifiableForNotification:notification];
    }
}

- (void)fetchAddNotification:(WLNotification *)notification success:(Block)success failure:(FailureBlock)failure {
    NSString *userIdentifier = notification.data[@"user_uid"];
    NSDictionary *userData = notification.data[@"user"];
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
    NSString *userIdentifier = notification.data[@"user_uid"];
    NSDictionary *userData = notification.data[@"user"];
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

- (void)fetchAddNotification:(WLNotification *)notification success:(Block)success failure:(FailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [super fetchAddNotification:notification success:^{
        [weakSelf.asset fetch:success];
    } failure:failure];
}

- (void)fetchUpdateNotification:(WLNotification *)notification success:(Block)success failure:(FailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [super fetchUpdateNotification:notification success:^{
        [weakSelf.asset fetch:success];
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
    if (wrap.valid && wrap.candies.count < [Constants recentCandiesLimit]) {
        [wrap fetch:Wrap.ContentTypeRecent success:nil failure:nil];
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
    if (notification.event != EventAdd) {
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
