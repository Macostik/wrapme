//
//  WLUser.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUser.h"
#import "NSDate+Formatting.h"
#import "WLSession.h"
#import "NSString+Additions.h"

@implementation WLUser

+ (NSDictionary*)pictureMapping {
	return @{@"large":@[@"large_avatar_url",@"contributor_large_avatar_url"],
			 @"medium":@[@"medium_avatar_url",@"contributor_medium_avatar_url"],
			 @"small":@[@"small_avatar_url",@"contributor_small_avatar_url"]};
}

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"phone_number":@"full_phone_number",
									@"user_uid":@"identifier",
									@"sign_in_count" : @"signInCount",
									@"is_creator":@"isCreator"}];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

- (BOOL)isEqualToEntry:(WLUser *)user {
	if (self.identifier.nonempty && user.identifier.nonempty) {
		return [super isEqualToEntry:user];
	}
	return NSStringEqual(self.phoneNumber, user.phoneNumber) && NSStringEqual(self.email, user.email);
}

@end

@implementation WLUser (CurrentUser)

+ (WLUser*)currentUser {
	return [WLSession user];
}

+ (void)setCurrentUser:(WLUser*)user {
	[WLSession setUser:user];
}

- (void)setCurrent {
	[WLUser setCurrentUser:self];
}

- (BOOL)isCurrentUser {
	return [[WLUser currentUser] isEqualToEntry:self];
}

@end

@implementation NSArray (WLUser)

- (NSArray*)usersByAddingCurrentUserAndUser:(WLUser*)user {
	return [[self usersByAddingUser:user] usersByAddingCurrentUser];
}

- (NSArray*)usersByAddingCurrentUser {
	return [self usersByAddingUser:[WLUser currentUser]];
}

- (NSArray *)usersByAddingUser:(WLUser *)user {
	if (user) {
		return [self entriesByAddingEntry:user];
	}
	return self;
}

- (NSArray *)usersByRemovingCurrentUserAndUser:(WLUser *)user {
	NSMutableArray* users = [NSMutableArray array];
	WLUser* currentUser = [WLUser currentUser];
	if (currentUser) {
		[users addObject:currentUser];
	}
	if (user) {
		[users addObject:user];
	}
	return [self usersByRemovingUsers:users];
}

- (NSArray*)usersByRemovingCurrentUser {
	return [self usersByRemovingUser:[WLUser currentUser]];
}

- (NSArray*)usersByRemovingUser:(WLUser*)user {
	return [self entriesByRemovingEntry:user];
}

- (NSArray*)usersByRemovingUsers:(NSArray*)users {
	return [self entriesByRemovingEntries:users];
}

@end
