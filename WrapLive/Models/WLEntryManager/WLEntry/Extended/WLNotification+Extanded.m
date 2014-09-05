//
//  WLNotification+Extanded.m
//  
//
//  Created by Yura Granchenko on 9/2/14.
//
//

#import "WLNotification+Extanded.h"
#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "WLWrap+Extended.h"
#import "WLBlocks.h"
#import "WLEntryManager.h"
#import "WLAPIManager.h"
#import "WLWrapBroadcaster.h"
#import "NSDate+Formatting.h"

@implementation WLNotification (Extanded)

+ (instancetype)notificationWithMessage:(PNMessage*)message {
	return [WLNotification API_entry:message.message];
}

+ (instancetype)notificationWithData:(NSDictionary *)data {
    return [WLNotification API_entry:data];
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
    NSMutableString* identifier = [NSMutableString string];
    NSString* wrapIdentifier = dictionary[@"wrap_uid"];
    NSString* candyIdentifier = dictionary[@"candy_uid"];
    NSString* commentIdentifier = dictionary[@"comment_uid"];
    if (wrapIdentifier.nonempty) {
        [identifier appendString:wrapIdentifier];
    }
    if (candyIdentifier.nonempty) {
        [identifier appendString:candyIdentifier];
    }
    if (commentIdentifier.nonempty) {
        [identifier appendString:commentIdentifier];
    }
    NSString* type = [dictionary stringForKey:@"wl_pn_type"];
    if (type.nonempty) {
        [identifier appendString:type];
    }
	return identifier;
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    WLNotificationType type = [dictionary integerForKey:@"wl_pn_type"];
    self.type = @(type);
    NSString* wrap_uid = [dictionary stringForKey:@"wrap_uid"];
    if (wrap_uid.nonempty) {
        WLWrap *wrap = [WLWrap entry:wrap_uid];
        if (wrap.valid) {
            NSString* candy_uid = [dictionary stringForKey:@"candy_uid"];
            if (candy_uid.nonempty) {
                WLCandy *candy = [WLCandy entry:candy_uid];
                if (candy.valid) {
                    candy.wrap = wrap;
                    if (type == WLNotificationImageCandyAddition ||
                        type == WLNotificationImageCandyDeletion ||
                        type == WLNotificationCandyCommentAddition ||
                        type == WLNotificationCandyCommentDeletion) {
                        candy.type = @(WLCandyTypeImage);
                    } else if (type == WLNotificationChatCandyAddition) {
                        candy.type = @(WLCandyTypeMessage);
                    }
                    NSString* comment_uid = [dictionary stringForKey:@"comment_uid"];
                    if (comment_uid.nonempty) {
                        WLComment *comment = [WLComment entry:comment_uid];
                        comment.candy = candy;
                        self.entry = comment;
                    } else {
                        self.entry = candy;
                    }
                    
                }
            } else {
                self.entry = wrap;
            }
        }
    }
    return self;
}

- (BOOL)isEntryOfType:(WLNotificationType)type {
    return [self.type integerValue] == type;
}

- (BOOL)deletion {
    WLNotificationType type = [self.type integerValue];
    return type == WLNotificationCandyCommentDeletion ||
           type == WLNotificationContributorDeletion  ||
           type == WLNotificationImageCandyDeletion   ||
           type == WLNotificationWrapDeletion;
}

- (void)fetch:(void (^)(void))completion {
    self.unread = @YES;
    WLNotificationType type = [self.type integerValue];
    id entry = self.entry;
    WLObjectBlock block = ^(id object) {
        if (type == WLNotificationContributorAddition) {
            [[WLUser currentUser] addWrap:entry];
            [entry broadcastCreation];
        } else if (type == WLNotificationContributorDeletion) {
            [entry remove];
        } else if (type == WLNotificationWrapDeletion) {
            [entry remove];
        } else if (type == WLNotificationImageCandyDeletion) {
            [entry remove];
        } else if (type == WLNotificationCandyCommentDeletion) {
            [entry remove];
        } else if (type == WLNotificationImageCandyAddition) {
            [[entry wrap] addCandy:entry];
            [entry broadcastCreation];
        } else if (type == WLNotificationChatCandyAddition) {
            [[entry wrap] addCandy:entry];
            [entry broadcastCreation];
        } else if (type == WLNotificationCandyCommentAddition) {
            
            [[entry candy] addComment:entry];
            [entry broadcastCreation];
            [[entry candy] broadcastChange];
        }
        [self save];
        completion();
    };
    
    if (![self deletion]) {
        if (type == WLNotificationContributorAddition) {
            if ([entry name].nonempty) {
                block(entry);
            } else {
                [entry fetch:block failure:^(NSError *error) { }];
            }
        } else if (type == WLNotificationImageCandyAddition) {
            if ([entry picture]) {
                block(entry);
            } else {
                [entry fetch:block failure:^(NSError *error) { }];
            }
        } else if (type == WLNotificationChatCandyAddition) {
            if ([entry message].nonempty) {
                block(entry);
            } else {
                [entry fetch:block failure:^(NSError *error) { }];
            }
        } else if (type == WLNotificationCandyCommentAddition) {
            if ([entry text].nonempty && [[[entry candy] comments] containsObject:entry]) {
                block(entry);
            } else {
                [[entry candy] fetch:block failure:^(NSError *error) { }];
            }
        }
    } else {
        block(nil);
    }
}


- (WLUser *)user {
    id entry = self.entry;
    WLNotificationType type = [self.type integerValue];
    if (type == WLNotificationContributorAddition) {
        return [WLUser currentUser];
    } else {
        return [entry contributor];
    }
    return nil;
}

- (NSString *)text {
    id entry = self.entry;
    WLNotificationType type = [self.type integerValue];;
    if (type == WLNotificationContributorAddition) {
        return [NSString stringWithFormat:@"added to '%@' wrap", [entry name]];
    } else if (type == WLNotificationImageCandyAddition) {
        return [NSString stringWithFormat:@"added photo to '%@' wrap", [[entry wrap] name]];
    } else if (type == WLNotificationChatCandyAddition) {
        return [NSString stringWithFormat:@"added chat message to '%@' wrap", [[entry wrap] name]];
    } else if (type == WLNotificationCandyCommentAddition) {
        return [NSString stringWithFormat:@"comment \"%@\" on the photo '%@'", [entry text], [[[entry candy] wrap] name]];
    }
    return nil;
}

- (NSDate *)date {
    id entry = self.entry;
    WLNotificationType type = [self.type integerValue];
    if (type == WLNotificationContributorAddition) {
        return [entry wrap].updatedAt;
    } else {
        return [entry createdAt];
    }
    return nil;
}

@end
