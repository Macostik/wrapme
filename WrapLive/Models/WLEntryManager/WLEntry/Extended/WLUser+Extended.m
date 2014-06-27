//
//  WLUser.m
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUser+Extended.h"
#import "WLEntryManager.h"
#import "WLNotificationBroadcaster.h"

@implementation WLUser (Extended)

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:@"user_uid"];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
	self.phone = [dictionary stringForKey:@"full_phone_number"];
	self.signInCount = [dictionary numberForKey:@"sign_in_count"];
	self.name = [dictionary stringForKey:@"name"];
    self.email = [dictionary stringForKey:@"email"];
	WLPicture* picture = [[WLPicture alloc] init];
	picture.large = [dictionary stringForKey:@"large_avatar_url"];
	picture.medium = [dictionary stringForKey:@"medium_avatar_url"];
	picture.small = [dictionary stringForKey:@"small_avatar_url"];
	self.picture = picture;
    return [super API_setup:dictionary relatedEntry:relatedEntry];
}

- (void)addWrap:(WLWrap *)wrap {
    if (!wrap) {
        return;
    }
    __weak typeof(self)weakSelf = self;
    self.wraps = [NSOrderedSet orderedSetWithBlock:^(NSMutableOrderedSet *set) {
        [set unionOrderedSet:weakSelf.wraps];
        [set addObject:wrap];
        [set sortEntries];
    }];
    [self save];
}

- (void)removeWrap:(WLWrap *)wrap {
    self.wraps = [self.wraps orderedSetByRemovingObject:wrap];
}

- (void)sortWraps {
    [WLUser currentUser].wraps = [[WLUser currentUser].wraps sortedEntries];
}

@end

@implementation WLUser (CurrentUser)

static WLUser *currentUser = nil;

+ (WLUser*)currentUser {
	if (!currentUser) {
		currentUser = [[WLUser entries:^(NSFetchRequest *request) {
			request.predicate = [NSPredicate predicateWithFormat:@"current == TRUE"];
		}] lastObject];
	}
	return currentUser;
}

+ (void)setCurrentUser:(WLUser*)user {
	currentUser = user;
	[[WLUser entries:^(NSFetchRequest *request) {
		request.predicate = [NSPredicate predicateWithFormat:@"current == TRUE"];
	}] all:^(WLUser* _user) {
		_user.current = @NO;
	}];
	user.current = @YES;
	[user save];
    if (user) {
        [[WLNotificationBroadcaster broadcaster] configure];
    }
}

- (void)setCurrent {
	[WLUser setCurrentUser:self];
}

- (BOOL)isCurrentUser {
	return [self.current boolValue];
}

@end

@implementation NSOrderedSet (WLUser)

- (NSOrderedSet*)usersByAddingCurrentUserAndUser:(WLUser*)user {
    return [self mutate:^(NSMutableOrderedSet *mutableCopy) {
        WLUser* currentUser = [WLUser currentUser];
        if (currentUser) {
            [mutableCopy addObject:currentUser];
        }
        if (user) {
            [mutableCopy addObject:user];
        }
    }];
}

- (NSOrderedSet*)usersByAddingCurrentUser {
    return [self usersByAddingUser:[WLUser currentUser]];
}

- (NSOrderedSet *)usersByAddingUser:(WLUser *)user {
	if (user) {
		return [self mutate:^(NSMutableOrderedSet *mutableCopy) {
            [mutableCopy addObject:user];
        }];
	}
	return self;
}

- (NSOrderedSet *)usersByRemovingCurrentUserAndUser:(WLUser *)user {
    return [self mutate:^(NSMutableOrderedSet *mutableCopy) {
        WLUser* currentUser = [WLUser currentUser];
        if (currentUser) {
            [mutableCopy removeObject:currentUser];
        }
        if (user) {
            [mutableCopy removeObject:user];
        }
    }];
}

- (NSOrderedSet*)usersByRemovingCurrentUser {
	return [self orderedSetByRemovingObject:[WLUser currentUser]];
}

@end

