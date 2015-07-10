//
//  WLNotification.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNotification.h"
#import "NSDate+Additions.h"
#import "WLAuthorization.h"
#import "WLEntryNotifier.h"
#import "WLAPIManager.h"
#import "WLEntryNotification.h"
#import "WLUpdateNotification.h"

@interface WLNotification ()

@end

@implementation WLNotification

@synthesize identifier = _identifier;

+ (NSMutableOrderedSet *)notificationsWithDataArray:(NSArray *)array {
    return [NSMutableOrderedSet orderedSetWithArray:[array map:^id(NSDictionary* data) {
        return [self notificationWithData:data];
    }]];
}

+ (instancetype)notificationWithData:(NSDictionary *)data {
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSString* typeString = [data objectForKey:@"msg_type"];
        if (typeString) {
            
            // this is to handle typing of notifications. If you need only WLEntryNotification instances call [WLEntryNotification notificationWithData:], if you need all instances call [WLNotification notificationWithData:]
            
            WLNotificationType type = [typeString integerValue];
            Class notificationClass = nil;
            if (self != [WLNotification class]) {
                if ([self isSupportedType:type]) {
                    notificationClass = self;
                }
            } else {
                NSArray *subclasses = @[[WLEntryNotification class],[WLUpdateNotification class]];
                for (Class subclass in subclasses) {
                    if ([subclass isSupportedType:type]) {
                        notificationClass = subclass;
                        break;
                    }
                }
            }
            
            if (notificationClass) {
                WLNotification* notification = [[notificationClass alloc] init];
                notification.type = type;
                [notification setup:data];
                return notification;
            }
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
}

- (void)prepare {
    
}

- (void)fetch:(WLBlock)success failure:(WLFailureBlock)failure {
    if (success) success();
}

- (void)finalize {
    
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
    return self.isSoundAllowed;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%i : %@", (int)self.type, self.identifier];
}

- (BOOL)supportsApplicationState:(UIApplicationState)state {
    return state == UIApplicationStateInactive || state == UIApplicationStateBackground;
}

- (BOOL)presentable {
    return NO;
}

@end
