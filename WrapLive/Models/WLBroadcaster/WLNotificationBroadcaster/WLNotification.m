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

@interface WLNotification ()

@end

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
            [notification setup:data];
			return notification;
		}
	}
	return nil;
}

- (void)setup:(NSDictionary*)data {
    
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
    
    switch (type) {
        case WLNotificationContributorAdd:
        case WLNotificationContributorDelete:
        case WLNotificationWrapDelete:
            self.targetEntry = [WLWrap entry:[data stringForKey:WLWrapUIDKey]];
            break;
        case WLNotificationCandyAdd:
        case WLNotificationCandyDelete:
            self.targetEntry = [WLCandy entry:[data stringForKey:WLCandyUIDKey]];
            break;
        case WLNotificationMessageAdd:
            self.targetEntry = [WLMessage entry:[data stringForKey:@"chat_uid"]];
            break;
        case WLNotificationCommentAdd:
        case WLNotificationCommentDelete:
            self.targetEntry = [WLComment entry:[data stringForKey:WLCommentUIDKey]];
            break;
        default:
            break;
    }
}

- (void)fetch:(WLBlock)completion {
    
    WLEntry* targetEntry = [self targetEntry];
    
    WLEvent event = self.event;
    
    WLObjectBlock block = ^(id object) {
        
        if (event == WLEventAdd) {
            if (self.type == WLNotificationCommentAdd && targetEntry.notifiable && !NSNumberEqual(targetEntry.unread, @YES)) {
                targetEntry.unread = @YES;
            }
            [targetEntry broadcastCreation];
        } else if (event == WLEventUpdate) {
            [targetEntry broadcastChange];
        } else if (event == WLEventDelete) {
            [targetEntry remove];
        }

        completion();
    };
    
    [targetEntry save];
    
    if (event == WLEventAdd) {
        [targetEntry fetchIfNeeded:block failure:nil];
    } else if (event == WLEventUpdate) {
        [targetEntry fetch:block failure:nil];
    } else if (event == WLEventDelete) {
        block(nil);
    }
}

@end

@implementation WLEntry (WLNotification)

- (BOOL)notifiable {
    return NO;
}

@end

@implementation WLComment (WLNotification)

- (BOOL)notifiable {
    WLCandy *candy = self.candy;
    if ([candy.contributor isCurrentUser]) {
        return YES;
    } else {
        NSUInteger index = [candy.comments indexOfObjectPassingTest:^BOOL(WLComment* _comment, NSUInteger idx, BOOL *stop) {
            return [_comment.contributor isCurrentUser];
        }];
        if (index != NSNotFound && [candy.comments indexOfObject:self] > index) {
            return YES;
        }
    }
    return NO;
}

@end
