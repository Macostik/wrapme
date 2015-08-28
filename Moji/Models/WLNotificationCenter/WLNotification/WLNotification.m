//
//  WLNotification.m
//  moji
//
//  Created by Ravenpod on 19.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotification.h"
#import "NSDate+Additions.h"
#import "WLAuthorization.h"
#import "WLEntryNotifier.h"
#import "WLEntry+WLAPIRequest.h"
#import "PubNub.h"
#import "NSDate+PNTimetoken.h"

@interface WLNotification ()

@end

@implementation WLNotification

@synthesize identifier = _identifier;

- (NSString *)identifier {
    if (!_identifier.nonempty) {
        _identifier = [NSString stringWithFormat:@"%lu_%@_%f", (unsigned long)self.type, self.entryIdentifier, self.date.timestamp];
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

+ (BOOL)isSupportedType:(WLNotificationType)type {
    return YES;
}

- (void)setup:(NSDictionary*)data {
    self.data = data;
    self.identifier = [data stringForKey:@"msg_uid"];
    self.publishedAt = [data dateForKey:@"msg_published_at"];
    
    WLNotificationType type = self.type;
    
    if (type == WLNotificationUpdateAvailable) {
        self.containsEntry = NO;
        return;
    }
    
    self.containsEntry = YES;
    
    self.isSoundAllowed = ([data objectForKey:@"pn_apns"] != nil);
    self.entryData = data;
    
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
        case WLNotificationCandyDelete:
        case WLNotificationCandyUpdate:{
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
    self.trimmed = self.entryData == nil;
    
    switch (type) {
        case WLNotificationCandyAdd:
        case WLNotificationCandyDelete:
        case WLNotificationMessageAdd: {
            self.containerIdentifier = [data stringForKey:WLWrapUIDKey];
        } break;
        case WLNotificationCommentAdd:
        case WLNotificationCommentDelete: {
            self.containerIdentifier = [data stringForKey:WLCandyUIDKey];
        } break;
        default:
            break;
    }
}

- (WLEntry *)entry {
    if (!_entry) {
        [self createTargetEntry];
    }
    return _entry.valid ? _entry : nil;
}

- (void)createTargetEntry {
    if (!self.containsEntry) {
        return;
    }
    NSDictionary *dictionary = self.entryData;
    WLNotificationType type = self.type;
    WLEntry *entry = nil;
    
    switch (type) {
        case WLNotificationContributorAdd:
        case WLNotificationContributorDelete:
        case WLNotificationWrapDelete:
        case WLNotificationWrapUpdate: {
            entry = dictionary ? [WLWrap API_entry:dictionary] : [WLWrap entry:self.entryIdentifier];
        } break;
        case WLNotificationCandyAdd:
        case WLNotificationCandyDelete:
        case WLNotificationCandyUpdate: {
            entry = dictionary ? [WLCandy API_entry:dictionary] : [WLCandy entry:self.entryIdentifier];
        } break;
        case WLNotificationMessageAdd: {
            entry = dictionary ? [WLMessage API_entry:dictionary] : [WLMessage entry:self.entryIdentifier];
        } break;
        case WLNotificationCommentAdd:
        case WLNotificationCommentDelete: {
            entry = dictionary ? [WLComment API_entry:dictionary] : [WLComment entry:self.entryIdentifier];
        } break;
        case WLNotificationUserUpdate: {
            if (dictionary) {
                [[WLAuthorization currentAuthorization] updateWithUserData:dictionary];
                entry = [WLUser API_entry:dictionary];
            } else {
                entry = [WLUser entry:self.entryIdentifier];
            }
        } break;
        default:
            break;
    }
    
    self.inserted = entry.inserted;
    
    if (entry.container == nil) {
        switch (type) {
            case WLNotificationCandyAdd:
            case WLNotificationCandyDelete:
            case WLNotificationMessageAdd: {
                entry.container = [WLWrap entry:self.containerIdentifier];
            } break;
            case WLNotificationCommentAdd:
            case WLNotificationCommentDelete: {
                entry.container = [WLCandy entry:self.containerIdentifier];
            } break;
            default:
                break;
        }
    }
    
    _entry = entry;
}

- (void)prepare {
    WLEvent event = self.event;
    
    WLEntry* entry = [self entry];
    
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
    
    if (event == WLEventDelete && ![self.entryClass entryExists:self.entryIdentifier]) {
        if (success) success();
        return;
    }
    
    WLEntry* entry = [weakSelf entry];
    
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
    
    WLEntry* entry = [self entry];
    
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
    return [NSString stringWithFormat:@"%i : %@", (int)self.type, self.entryIdentifier];
}

- (BOOL)presentable {
    return self.event != WLEventDelete;
}

@end

@implementation WLEntry (WLNotification)

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
    [self notifyOnAddition:nil];
}

- (void)finalizeUpdateNotification:(WLNotification *)notification {
    [self notifyOnUpdate:nil];
}

- (void)finalizeDeleteNotification:(WLNotification *)notification {
    [self remove];
}

@end

@implementation WLContribution (WLNotification)

- (BOOL)notifiableForNotification:(WLNotification*)notification {
    WLEvent event = notification.event;
    if (event == WLEventAdd) {
        return !self.contributedByCurrentUser;
    } else if (event == WLEventUpdate) {
        return ![self.editor isCurrentUser];
    }
    return NO;
}

@end

@implementation WLUser (WLNotification)

@end

@implementation WLWrap (WLNotification)

- (BOOL)notifiableForNotification:(WLNotification *)notification {
    if (notification.event == WLEventAdd) {
        NSString *userIdentifier = notification.data[WLUserUIDKey] ? : notification.data[WLUserKey][WLUserUIDKey];
        return !self.contributedByCurrentUser && ![userIdentifier isEqualToString:[WLUser currentUser].identifier];
    } else {
        return [super notifiableForNotification:notification];
    }
}

- (void)fetchAddNotification:(WLNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    NSString *userIdentifier = notification.data[WLUserUIDKey];
    NSDictionary *userData = notification.data[WLUserKey];
    WLUser *user = userData ? [WLUser API_entry:userData] : [WLUser entry:userIdentifier];
    if (!user) {
        user = [WLUser currentUser];
    }
    if (![self.contributors containsObject:user]) {
        [self addContributorsObject:user];
    }
    [super fetchAddNotification:notification success:success failure:failure];
}

- (void)finalizeAddNotification:(WLNotification *)notification {
    [super finalizeAddNotification:notification];
    NSDictionary *userData = notification.data[@"inviter"];
    if (userData) {
        notification.requester = [WLUser API_entry:userData];
    }
}

- (void)finalizeDeleteNotification:(WLNotification *)notification {
    NSString *userIdentifier = notification.data[WLUserUIDKey];
    NSDictionary *userData = notification.data[WLUserKey];
    WLUser *user = userData ? [WLUser API_entry:userData] : [WLUser entry:userIdentifier];
    if (!user || [user isCurrentUser]) {
        [super finalizeDeleteNotification:notification];
    } else {
        __weak typeof(self)weakSelf = self;
        [self notifyOnUpdate:^(id object) {
            [weakSelf removeContributorsObject:user];
        }];
    }
}

@end

@implementation WLCandy (WLNotification)

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
    WLWrap *wrap = self.wrap;
    [super finalizeDeleteNotification:notification];
    if (wrap.valid && !wrap.candies.nonempty) {
        [wrap fetch:nil success:nil failure:nil];
    }
}

@end

@implementation WLMessage (WLNotification)

- (void)finalizeAddNotification:(WLNotification *)notification {
    if (notification.inserted) [self markAsUnreadIfNeededForNotification:notification];
    [super finalizeAddNotification:notification];
}

@end

@implementation WLComment (WLNotification)

- (void)finalizeAddNotification:(WLNotification *)notification {
    WLCandy *candy = self.candy;
    if (candy.valid) candy.commentCount = candy.comments.count;
    if (notification.inserted) [self markAsUnreadIfNeededForNotification:notification];
    [super finalizeAddNotification:notification];
}

- (BOOL)notifiableForNotification:(WLNotification*)notification {
    if (notification.event != WLEventAdd) {
        return [super notifiableForNotification:notification];
    }
    
    WLUser *currentUser = [WLUser currentUser];
    
    if (self.contributor == currentUser) {
        return NO;
    }
    WLCandy *candy = self.candy;
    if (candy.contributor == currentUser) {
        return YES;
    } else {
        for (WLComment *comment in candy.comments) {
            if (comment.contributor == currentUser) {
                return YES;
                break;
            }
        }
    }
    return NO;
}

@end
