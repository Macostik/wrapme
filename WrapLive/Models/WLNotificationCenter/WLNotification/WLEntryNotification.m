//
//  WLEntryNotification.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryNotification.h"
#import "WLSoundPlayer.h"

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
        [self createTargetEntry];
    }
    return _targetEntry.valid ? _targetEntry : nil;
}

- (void)createTargetEntry {
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
        case WLNotificationCandyDelete:
        case WLNotificationCandyUpdate: {
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
    
    self.inserted = targetEntry.inserted;
    
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

- (void)prepare {
    WLEvent event = self.event;
    
    WLEntry* targetEntry = [self targetEntry];
    
    if (!targetEntry) {
        return;
    }
    
    if (event == WLEventAdd) {
        [targetEntry prepareForAddNotification:self];
    } else if (event == WLEventUpdate) {
        [targetEntry prepareForUpdateNotification:self];
    } else if (event == WLEventDelete) {
        [targetEntry prepareForDeleteNotification:self];
    }
}

- (void)finalize {
    WLEvent event = self.event;
    
    WLEntry* targetEntry = [self targetEntry];
    
    if (!targetEntry) {
        return;
    }
    
    if (event == WLEventAdd) {
        [targetEntry finalizeAddNotification:self];
    } else if (event == WLEventUpdate) {
        [targetEntry finalizeUpdateNotification:self];
    } else if (event == WLEventDelete) {
        [targetEntry finalizeDeleteNotification:self];
    }
}

- (void)fetch:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak __typeof(self)weakSelf = self;
    
    WLEvent event = self.event;
    
    if (event == WLEventDelete && ![self.entryClass entryExists:self.entryIdentifier]) {
        if (success) success();
        return;
    }
    
    WLEntry* targetEntry = [weakSelf targetEntry];
    
    if (!targetEntry) {
        if (success) success();
        return;
    }
    
    if (event == WLEventAdd) {
        [targetEntry fetchAddNotification:self success:success failure:failure];
    } else if (event == WLEventUpdate) {
        [targetEntry fetchUpdateNotification:self success:success failure:failure];
    } else if (event == WLEventDelete) {
        [targetEntry fetchDeleteNotification:self success:success failure:failure];
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
            return [self.targetEntry notifiableForEvent:self.event];
            break;
        default:
            return NO;
            break;
    }
}

- (BOOL)presentable {
    return self.event != WLEventDelete;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%i : %@", (int)self.type, self.entryIdentifier];
}

@end

@implementation WLEntry (WLNotification)

- (BOOL)notifiableForEvent:(WLEvent)event {
    return NO;
}

- (BOOL)notifiableByPreferences {
    return YES;
}

- (void)markAsUnreadIfNeededForEvent:(WLEvent)event {
    if ([self notifiableForEvent:event]) [self markAsUnread];
}

- (void)prepareForAddNotification:(WLEntryNotification *)notification {
    
}

- (void)prepareForUpdateNotification:(WLEntryNotification *)notification {
    
}

- (void)prepareForDeleteNotification:(WLEntryNotification *)notification {
    
}

- (void)fetchAddNotification:(WLEntryNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    [self recursivelyFetchIfNeeded:success failure:failure];
}

- (void)fetchUpdateNotification:(WLEntryNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    if (notification.trimmed) {
        [self fetch:^(id object) {
            if (success) success();
        } failure:failure];
    } else {
        if (success) success();
    }
}

- (void)fetchDeleteNotification:(WLEntryNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    if (success) success();
}

- (void)finalizeAddNotification:(WLEntryNotification *)notification {
    [self notifyOnAddition:nil];
}

- (void)finalizeUpdateNotification:(WLEntryNotification *)notification {
    [self notifyOnUpdate:nil];
}

- (void)finalizeDeleteNotification:(WLEntryNotification *)notification {
    [self remove];
}

- (UILocalNotification *)localNotificationForData:(NSDictionary *)userInfo {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.userInfo = userInfo;
    if ([notification respondsToSelector:@selector(setAlertTitle:)]) {
        notification.alertTitle = [self alertTitle];
    }
    notification.alertBody = [self alertBody];
    notification.soundName = [self soundName];
    return notification;
}

- (NSString *)alertTitle {return nil;}
- (NSString *)alertBody {return nil;}
- (NSString *)soundName {return nil;}
- (NSString *)category {return nil;}

@end

@implementation WLContribution (WLNotification)

- (BOOL)notifiableForEvent:(WLEvent)event {
    if (event == WLEventAdd) {
        return !self.contributedByCurrentUser;
    } else if (event == WLEventUpdate) {
        return ![self.editor isCurrentUser];
    }
    return NO;
}

@end

@implementation WLUser (WLNotification)

- (NSString *)soundName{
    return [WLSoundFileName(WLSound_s01) stringByAppendingString:@".wav"];;
}

@end

@implementation WLWrap (WLNotification)

- (void)fetchAddNotification:(WLEntryNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
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

- (void)finalizeDeleteNotification:(WLEntryNotification *)notification {
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

- (void)fetchAddNotification:(WLEntryNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [super fetchAddNotification:notification success:^{
        [weakSelf.picture fetch:success];
    } failure:failure];
}

- (void)fetchUpdateNotification:(WLEntryNotification *)notification success:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [super fetchUpdateNotification:notification success:^{
        [weakSelf.picture fetch:success];
    } failure:failure];
}

- (void)finalizeAddNotification:(WLEntryNotification *)notification {
    if (notification.inserted) [self markAsUnreadIfNeededForEvent:notification.event];
    [super finalizeAddNotification:notification];
}

- (void)finalizeUpdateNotification:(WLEntryNotification *)notification {
    [self markAsUnreadIfNeededForEvent:notification.event];
    [super finalizeUpdateNotification:notification];
}

- (void)finalizeDeleteNotification:(WLEntryNotification *)notification {
    WLWrap *wrap = self.wrap;
    [super finalizeDeleteNotification:notification];
    if (wrap.valid && !wrap.candies.nonempty) {
        [wrap fetch:nil success:nil failure:nil];
    }
}

- (UILocalNotification *)localNotificationForData:(NSDictionary *)userInfo {
    UILocalNotification *candyNotification = [super localNotificationForData:userInfo];
    NSInteger eventType = [userInfo integerForKey:@"msg_type"];
    if ([candyNotification respondsToSelector:@selector(setAlertTitle:)])
    candyNotification.alertTitle = [self alertTitleForType:eventType];
    candyNotification.alertBody = [self alertBodyForType:eventType];
    return candyNotification;
    
}

- (NSString *)alertTitleForType:(NSInteger)type {
    if (type == WLNotificationCandyAdd) {
        return [NSString stringWithFormat:WLLS(@"APNS_TT02"), [WLUser currentUser].name];
    } else if (type == WLNotificationCandyUpdate) {
        return [NSString stringWithFormat:WLLS(@"APNS_TT05"), self.wrap.name];
    }
    return nil;
}

- (NSString *)alertBodyForType:(NSInteger)type {
    if (type == WLNotificationCandyAdd) {
        return [NSString stringWithFormat:WLLS(@"APNS_MSG02"), self.contributor.name];
    } else if (type == WLNotificationCandyUpdate) {
        return [NSString stringWithFormat:WLLS(@"APNS_MSG05"), self.editor.name];
    }
    return nil;
}

- (BOOL)notifiableByPreferences {
    return self.wrap.isCandyNotifiable;
}

@end

@implementation WLMessage (WLNotification)

- (void)finalizeAddNotification:(WLEntryNotification *)notification {
    if (notification.inserted) [self markAsUnreadIfNeededForEvent:notification.event];
    [super finalizeAddNotification:notification];
}

- (NSString *)alertTitle {
    return [NSString stringWithFormat:WLLS(@"APNS_TT04"), self.contributor.name];
}

- (NSString *)alertBody {
    return [NSString stringWithFormat:WLLS(@"APNS_MSG04"), self.text, self.wrap.name];
}

- (NSString *)soundName {
    return [WLSoundFileName(WLSound_s03) stringByAppendingString:@".wav"];
}

- (NSString *)category {
    return @"chat";
}

- (BOOL)notifiableByPreferences {
    return self.wrap.isChatNotifiable;
}

@end

@implementation WLComment (WLNotification)

- (void)finalizeAddNotification:(WLEntryNotification *)notification {
    WLCandy *candy = self.candy;
    if (candy.valid) candy.commentCount = candy.comments.count;
    if (notification.inserted) [self markAsUnreadIfNeededForEvent:notification.event];
    [super finalizeAddNotification:notification];
}

- (NSString *)alertTitle {
    return [NSString stringWithFormat:WLLS(@"APNS_TT03"), self.contributor.name];
}

- (NSString *)alertBody {
    return [NSString stringWithFormat:WLLS(@"APNS_MSG03"), self.text];
}

- (NSString *)soundName {
    return [WLSoundFileName(WLSound_s02) stringByAppendingString:@".wav"];;
}

@end