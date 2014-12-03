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
    BOOL firstTimeUse = [dictionary integerForKey:WLSignInCountKey] == 1;
	if (self.firstTimeUse != firstTimeUse) self.firstTimeUse = firstTimeUse;
    NSString* name = [dictionary stringForKey:WLNameKey];
	if (!NSStringEqual(self.name, name)) self.name = name;
    [self editPicture:[dictionary stringForKey:WLLargeAvatarKey]
               medium:[dictionary stringForKey:WLMediumAvatarKey]
                small:[dictionary stringForKey:WLSmallAvatarKey]];
    
    NSMutableOrderedSet* devices = [WLDevice API_entries:[dictionary arrayForKey:@"devices"] relatedEntry:self];
    if (![self.devices isEqualToOrderedSet:devices]) self.devices = devices;
    self.phones = nil;
    
    return [super API_setup:dictionary relatedEntry:relatedEntry];
}

- (void)addWrap:(WLWrap *)wrap {
    if (!wrap || [self.wraps containsObject:wrap]) {
        [self sortWraps];
        return;
    }
    if (!self.wraps) self.wraps = [NSMutableOrderedSet orderedSet];
    [self.wraps addObject:wrap comparator:comparatorByUpdatedAt descending:YES];
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
    NSMutableOrderedSet* wraps = self.wraps;
    if ([wraps sortByUpdatedAt]) {
        self.wraps = wraps;
    }
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
            if (currentUser.current) currentUser.current = NO;
        }
    } else {
        [[WLUser entries:^(NSFetchRequest *request) {
            request.predicate = [NSPredicate predicateWithFormat:@"current == TRUE"];
        }] all:^(WLUser* _user) {
            if (_user.current) _user.current = NO;
        }];
    }
	currentUser = user;
	if (!user.current) user.current = YES;
    if (user) {
        [[WLNotificationCenter defaultCenter] subscribe];
#ifndef DEBUG
        [Crashlytics setUserEmail:[WLAuthorization currentAuthorization].email];
        [Crashlytics setUserIdentifier:user.identifier];
        [Crashlytics setUserName:user.name];
#endif
    }
}

- (void)setCurrent {
	[WLUser setCurrentUser:self];
}

- (BOOL)isCurrentUser {
	return self.current;
}

@end

