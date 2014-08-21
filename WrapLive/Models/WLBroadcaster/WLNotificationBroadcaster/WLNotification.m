//
//  WLNotification.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNotification.h"
#import "NSDictionary+Extended.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "WLComment.h"
#import "NSString+Additions.h"
#import "WLBlocks.h"
#import "WLAPIManager.h"
#import "WLWrapBroadcaster.h"

@implementation WLNotification

+ (NSMutableOrderedSet *)notificationsWithDataArray:(NSArray *)array {
    return [NSMutableOrderedSet orderedSetWithArray:[array map:^id(NSDictionary* data) {
        return [WLNotification notificationWithData:data];
    }]];
}

+ (instancetype)notificationWithMessage:(PNMessage*)message {
	return [self notificationWithData:message.message];
}

+ (instancetype)notificationWithData:(NSDictionary *)data {
	if ([data isKindOfClass:[NSDictionary class]]) {
		NSString* type = [data objectForKey:@"wl_pn_type"];
		if (type) {
			WLNotification* notification = [[self alloc] init];
			notification.type = [type integerValue];
			notification.data = data;
			return notification;
		}
	}
	return nil;
}

- (WLWrap *)wrap {
	if (!_wrap) {
		NSString* identifier = [self.data stringForKey:@"wrap_uid"];
		if (identifier.nonempty) {
			WLWrap *wrap = [WLWrap entry:identifier];
            if (wrap.valid) {
                _wrap = wrap;
                [wrap addCandy:self.candy];
            }
		}
	}
	return _wrap;
}

- (WLCandy *)candy {
	if (!_candy) {
		NSString* identifier = [self.data stringForKey:@"candy_uid"];
		if (identifier.nonempty) {
			WLCandy *candy = [WLCandy entry:identifier];
            if (candy.valid) {
                [candy touch];
                _candy = candy;
                WLNotificationType type = self.type;
                if (type == WLNotificationImageCandyAddition || type == WLNotificationImageCandyDeletion || type == WLNotificationCandyCommentAddition || type == WLNotificationCandyCommentDeletion) {
                    candy.type = @(WLCandyTypeImage);
                } else if (type == WLNotificationChatCandyAddition) {
                    candy.type = @(WLCandyTypeMessage);
                }
//                [candy addComment:self.comment];
            }
		}
	}
	return _candy;
}

- (WLComment *)comment {
	if (!_comment) {
		NSString* identifier = [self.data stringForKey:@"comment_uid"];
		if (identifier.nonempty) {
            WLComment *comment = [WLComment entry:identifier];
            if (comment.valid) {
                _comment = comment;
            }
		}
	}
	return _comment;
}

- (BOOL)deletion {
    WLNotificationType type = self.type;
    return type == WLNotificationCandyCommentDeletion || type == WLNotificationContributorDeletion || type == WLNotificationImageCandyDeletion || type == WLNotificationWrapDeletion;
}

- (void)fetch:(void (^)(void))completion {
    WLNotificationType type = self.type;
    WLWrap* wrap = self.wrap;
    WLCandy* candy = self.candy;
    WLComment* comment = self.comment;
    WLObjectBlock block = ^(id object) {
        if (type == WLNotificationContributorAddition) {
            [[WLUser currentUser] addWrap:wrap];
            [wrap broadcastCreation];
        } else if (type == WLNotificationContributorDeletion) {
            [wrap remove];
        } else if (type == WLNotificationWrapDeletion) {
            [wrap remove];
        } else if (type == WLNotificationImageCandyDeletion) {
            [candy remove];
        } else if (type == WLNotificationCandyCommentDeletion) {
            [comment remove];
        } else if (type == WLNotificationImageCandyAddition) {
            [wrap addCandy:candy];
        } else if (type == WLNotificationChatCandyAddition) {
            [wrap addCandy:candy];
        } else if (type == WLNotificationCandyCommentAddition) {
            [wrap addCandy:candy];
        }
        completion();
    };
    
    if (![self deletion]) {
        wrap.unread = @YES;
        if (type == WLNotificationContributorAddition) {
            [wrap fetch:block failure:^(NSError *error) {
            }];
        } else {
            candy.unread = @YES;
            [candy fetch:block failure:^(NSError *error) {
            }];
        }
    } else {
        block(nil);
    }
}

- (WLUser *)user {
    WLNotificationType type = self.type;
    if (type == WLNotificationContributorAddition) {
        return [WLUser currentUser];
    } else if (type == WLNotificationImageCandyAddition) {
        return self.candy.contributor;
    } else if (type == WLNotificationChatCandyAddition) {
        return self.candy.contributor;
    } else if (type == WLNotificationCandyCommentAddition) {
        return self.comment.contributor;
    }
    return nil;
}

- (NSString *)text {
    WLNotificationType type = self.type;
    if (type == WLNotificationContributorAddition) {
        return [NSString stringWithFormat:@"added to '%@' wrap", self.wrap.name];
    } else if (type == WLNotificationImageCandyAddition) {
        return [NSString stringWithFormat:@"added photo to '%@' wrap", self.wrap.name];
    } else if (type == WLNotificationChatCandyAddition) {
        return [NSString stringWithFormat:@"added chat message to '%@' wrap", self.wrap.name];
    } else if (type == WLNotificationCandyCommentAddition) {
        return [NSString stringWithFormat:@"comment \"%@\" on the photo '%@'", self.comment.text, self.wrap.name];
    }
    return nil;
}

- (NSDate *)date {
    WLNotificationType type = self.type;
    if (type == WLNotificationContributorAddition) {
        return self.wrap.updatedAt;
    } else if (type == WLNotificationImageCandyAddition) {
        return self.candy.createdAt;
    } else if (type == WLNotificationChatCandyAddition) {
        return self.candy.createdAt;
    } else if (type == WLNotificationCandyCommentAddition) {
        return self.comment.createdAt;
    }
    return nil;
}

@end
