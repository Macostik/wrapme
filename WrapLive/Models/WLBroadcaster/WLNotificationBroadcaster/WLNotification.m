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
			_wrap = [WLWrap entry:identifier];
            if (self.candy) {
                [_wrap addCandy:self.candy];
            }
		}
	}
	return _wrap;
}

- (WLCandy *)candy {
	if (!_candy) {
		NSString* identifier = [self.data stringForKey:@"candy_uid"];
		if (identifier.nonempty) {
			_candy = [WLCandy entry:identifier];
            _candy.wrap = self.wrap;
            
			if (self.type == WLNotificationImageCandyAddition || self.type == WLNotificationImageCandyDeletion || self.type == WLNotificationCandyCommentAddition || self.type == WLNotificationCandyCommentDeletion) {
				_candy.type = @(WLCandyTypeImage);
			} else if (self.type == WLNotificationChatCandyAddition) {
				_candy.type = @(WLCandyTypeMessage);
			}
            
            if (self.comment) {
                [_candy addComment:self.comment];
            }
		}
	}
	return _candy;
}

- (WLComment *)comment {
	if (!_comment) {
		NSString* identifier = [self.data stringForKey:@"comment_uid"];
		if (identifier.nonempty) {
			_comment = [WLComment entry:identifier];
            _comment.candy = self.candy;
		}
	}
	return _comment;
}

- (BOOL)deletion {
    WLNotificationType type = self.type;
    return type == WLNotificationCandyCommentDeletion || type == WLNotificationContributorDeletion || type == WLNotificationImageCandyDeletion || type == WLNotificationWrapDeletion;
}

- (void)fetch:(void (^)(void))completion {
    __weak typeof(self)weakSelf = self;
    WLObjectBlock block = ^(id object) {
        WLNotificationType type = self.type;
        if (type == WLNotificationContributorAddition) {
            [[WLUser currentUser] addWrap:weakSelf.wrap];
            [weakSelf.wrap broadcastCreation];
        } else if (type == WLNotificationContributorDeletion) {
            [weakSelf.wrap remove];
        } else if (type == WLNotificationWrapDeletion) {
            [weakSelf.wrap remove];
        } else if (type == WLNotificationImageCandyDeletion) {
            [weakSelf.candy remove];
        } else if (type == WLNotificationCandyCommentDeletion) {
            [weakSelf.comment remove];
        } else if (type == WLNotificationImageCandyAddition) {
            [weakSelf.wrap addCandy:weakSelf.candy];
        } else if (type == WLNotificationChatCandyAddition) {
            [weakSelf.wrap addCandy:weakSelf.candy];
        } else if (type == WLNotificationCandyCommentAddition) {
            [weakSelf.wrap addCandy:weakSelf.candy];
        }
        completion();
    };
    
    if (![self deletion]) {
        self.wrap.unread = @YES;
        if (self.type == WLNotificationContributorAddition) {
            [self.wrap fetch:block failure:block];
        } else {
            self.candy.unread = @YES;
            [self.candy fetch:block failure:block];
        }
    } else {
        block(nil);
    }
}

@end
