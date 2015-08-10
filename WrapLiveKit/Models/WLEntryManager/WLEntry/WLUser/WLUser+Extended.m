//
//  WLUser.m
//  CoreData1
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUser+Extended.h"
#import "WLEntryManager.h"
#import "WLAuthorization.h"
#import "WLEntryNotifier.h"
#import "NSDate+Additions.h"
#import "NSDate+Formatting.h"

@implementation WLUser (Extended)

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:WLUserUIDKey];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    BOOL firstTimeUse = [dictionary integerForKey:WLSignInCountKey] == 1;
	if (self.firstTimeUse != firstTimeUse) self.firstTimeUse = firstTimeUse;
    NSString* name = [dictionary stringForKey:WLNameKey];
	if (!NSStringEqual(self.name, name)) self.name = name;
    [self editPicture:[dictionary stringForKey:WLLargeAvatarKey]
               medium:[dictionary stringForKey:WLMediumAvatarKey]
                small:[dictionary stringForKey:WLSmallAvatarKey]];
    
    if (dictionary[@"devices"]) {
        NSSet* devices = [WLDevice API_entries:[dictionary arrayForKey:@"devices"] relatedEntry:self];
        if (![self.devices isEqualToSet:devices]) {
            self.devices = devices;
            self.phones = nil;
        }
    }
    
    return [super API_setup:dictionary relatedEntry:relatedEntry];
}

- (void)addWrap:(WLWrap *)wrap {
    [self addWrapsObject:wrap];
}

- (void)removeWrap:(WLWrap *)wrap {
    [self removeWrapsObject:wrap];
}

- (NSMutableOrderedSet *)sortedWraps {
    return [[NSMutableOrderedSet orderedSetWithSet:self.wraps] sortByCreatedAt];
}

- (BOOL)isSignupCompleted {
    return self.name.nonempty && self.picture.medium.nonempty;
}

- (BOOL)isInvited {
    if ([self isCurrentUser]) return NO;
    NSSet *devices = self.devices;
    if (devices.nonempty) {
        for (WLDevice *device in devices) {
            if (device.activated) {
                return NO;
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (NSDate *)invitedAt {
    return [(WLDevice*)[self.devices anyObject] invitedAt];
}

- (NSString *)invitationHintText {
    NSDate *invitedAt = self.invitedAt;
    if (invitedAt) {
        return [NSString stringWithFormat:@"Invite sent %@. Swipe to resend invite", [invitedAt stringWithDateStyle:NSDateFormatterLongStyle]];
    } else {
        return @"Invite sent. Swipe to resend invite";
    }
}

@end

@implementation WLUser (CurrentUser)

static WLUser *currentUser = nil;

static NSString *_combinedIdentifier = nil;

+ (NSString *)combinedIdentifier {
    return _combinedIdentifier;
}

+ (WLUser*)currentUser {
	if (!currentUser) {
		WLUser *currentUser = [[WLUser entriesWhere:@"current == TRUE"] lastObject];
        if (currentUser) {
            [self setCurrentUser:currentUser];
        }
	}
	return currentUser;
}

+ (void)setCurrentUser:(WLUser*)user {
    if (currentUser) {
        if (![currentUser isEqualToEntry:user]) {
            if (currentUser.current) currentUser.current = NO;
        }
    } else {
        [[WLUser entriesWhere:@"current == TRUE"] all:^(WLUser* _user) {
            _user.current = NO;
        }];
    }
	currentUser = user;
	if (!user.current) user.current = YES;
    if (user) {
        WLAuthorization *authorization = [WLAuthorization currentAuthorization];
        _combinedIdentifier = [NSString stringWithFormat:@"%@-%@", user.identifier, authorization.deviceUID];
        [user notifyOnAddition:nil];
    }
}

- (void)setCurrent {
	[WLUser setCurrentUser:self];
}

- (BOOL)isCurrentUser {
	return self.current;
}

@end

