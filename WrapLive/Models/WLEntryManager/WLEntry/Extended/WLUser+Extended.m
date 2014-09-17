//
//  WLUser.m
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUser+Extended.h"
#import "WLEntryManager.h"
#import "WLNotificationCenter.h"
#import "WLAuthorization.h"

@implementation WLUser (Extended)

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:WLUserUIDKey];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    NSNumber* signInCount = [dictionary numberForKey:WLSignInCountKey];
	if (!NSNumberEqual(self.signInCount, signInCount)) self.signInCount = signInCount;
    NSString* name = [dictionary stringForKey:WLNameKey];
	if (!NSStringEqual(self.name, name)) self.name = name;
    
    if ([self isCurrentUser]) {
        WLAuthorization* authorization = [WLAuthorization currentAuthorization];
        NSString *email = [dictionary stringForKey:WLEmailKey];
        if (!NSStringEqual(authorization.email, email) && email.nonempty)
            authorization.email = email;
        NSString *unconfirmed_email = [dictionary stringForKey:WLUnconfirmedEmail];
        if (!NSStringEqual(authorization.unconfirmed_email, unconfirmed_email) && unconfirmed_email.nonempty)
            authorization.unconfirmed_email = unconfirmed_email;
        NSNumber* confirmed = [dictionary numberForKey:WLConfirmedKey];
        if (!NSNumberEqual(self.confirmed, confirmed)) self.confirmed = confirmed;
    }
    
    [self editPicture:[dictionary stringForKey:WLLargeAvatarKey]
               medium:[dictionary stringForKey:WLMediumAvatarKey]
                small:[dictionary stringForKey:WLSmallAvatarKey]];
    return [super API_setup:dictionary relatedEntry:relatedEntry];
}

- (void)addWrap:(WLWrap *)wrap {
    if (!wrap || [self.wraps containsObject:wrap]) {
        [self sortWraps];
        return;
    }
    if (!self.wraps) self.wraps = [NSMutableOrderedSet orderedSet];
    [self.wraps addObject:wrap];
    [self sortWraps];
    [self save];
}

- (void)addWraps:(NSOrderedSet *)wraps {
    if (!self.wraps) self.wraps = [NSMutableOrderedSet orderedSet];
    [self.wraps unionOrderedSet:wraps];
    [self sortWraps];
}

- (void)removeWrap:(WLWrap *)wrap {
    if ([self.wraps containsObject:wrap]) {
        [self.wraps removeObject:wrap];
    }
}

- (void)sortWraps {
    [self.wraps sortByUpdatedAtDescending];
}

- (NSMutableOrderedSet *)sortedWraps {
    [self sortWraps];
    return self.wraps;
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
    if (currentUser) {
        if (![currentUser isEqualToEntry:user]) {
            currentUser.current = @NO;
        }
    } else {
        [[WLUser entries:^(NSFetchRequest *request) {
            request.predicate = [NSPredicate predicateWithFormat:@"current == TRUE"];
        }] all:^(WLUser* _user) {
            _user.current = @NO;
        }];
    }
	currentUser = user;
	user.current = @YES;
	[user save];
    if (user) {
        [[WLNotificationCenter defaultCenter] configure];
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

