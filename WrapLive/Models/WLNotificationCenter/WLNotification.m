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
#import "NSDate+Additions.h"

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
		NSString* type = [data objectForKey:@"msg_type"];
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
        case WLNotificationWrapDelete: {
            NSDictionary* dictionary = [data dictionaryForKey:WLWrapKey];
            self.targetEntry = dictionary ? [WLWrap API_entry:dictionary] : [WLWrap entry:[data stringForKey:WLWrapUIDKey]];
        } break;
        case WLNotificationCandyAdd:
        case WLNotificationCandyDelete: {
            NSDictionary* dictionary = [data dictionaryForKey:WLCandyKey];
            self.targetEntry = dictionary ? [WLCandy API_entry:dictionary] : [WLCandy entry:[data stringForKey:WLCandyUIDKey]];
        } break;
        case WLNotificationMessageAdd: {
            NSDictionary* dictionary = [data dictionaryForKey:WLMessageKey];
            self.targetEntry = dictionary ? [WLMessage API_entry:dictionary] : [WLMessage entry:[data stringForKey:WLMessageUIDKey]];
        } break;
        case WLNotificationCommentAdd:
        case WLNotificationCommentDelete: {
            NSDictionary* dictionary = [data dictionaryForKey:WLCommentKey];
            self.targetEntry = dictionary ? [WLComment API_entry:dictionary] : [WLComment entry:[data stringForKey:WLCommentUIDKey]];
        } break;
        default:
            break;
    }
}

- (void)fetch:(WLBlock)completion {
    
    WLEntry* targetEntry = [self targetEntry];
    
    WLEvent event = self.event;
    
    __weak __typeof(self)weakSelf = self;
    WLObjectBlock block = ^(id object) {
        if (event == WLEventAdd) {
            switch (weakSelf.type) {
                case WLNotificationCommentAdd:
                    if (targetEntry.notifiable && !NSNumberEqual(targetEntry.unread, @YES)) targetEntry.unread = @YES;
                    break;
                case WLNotificationCandyAdd:
                case WLNotificationMessageAdd:
                    if (!NSNumberEqual(targetEntry.unread, @YES)) targetEntry.unread = @YES;
                    break;
                default:
                    break;
            }
            [targetEntry broadcastCreation];
        } else if (event == WLEventUpdate) {
            [targetEntry broadcastChange];
        } else if (event == WLEventDelete) {
            [targetEntry remove];
        }
        
        completion();
    };
    
    if (event == WLEventAdd) {
        [targetEntry fetchIfNeeded:block failure:nil];
    } else if (event == WLEventUpdate) {
        [targetEntry fetch:block failure:nil];
    } else if (event == WLEventDelete) {
        block(nil);
    }
}

- (BOOL)playSound {
    WLNotificationType type = self.type;
    switch (type) {
        case WLNotificationContributorAdd:
        case WLNotificationMessageAdd:
            return YES;
            break;
        case WLNotificationCommentAdd:
            return self.targetEntry.notifiable;
            break;
        default:
            return NO;
            break;
    }
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

@implementation WLUser (WLNotification)

- (NSMutableOrderedSet *)notifications {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdAt >= %@ AND contributor != %@", [NSDate dayAgo], [WLUser currentUser]];
    return [[WLComment entriesWithPredicate:predicate sorterByKey:@"createdAt"] map:^id (WLComment *comment) {
        return comment.notifiable ? comment : nil;
    }];
}

- (NSUInteger)unreadNotificationsCount {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdAt >= %@ AND contributor != %@ AND unread == YES",
                              [NSDate dayAgo], [WLUser currentUser]];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([WLComment class])];
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
