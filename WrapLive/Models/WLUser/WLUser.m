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

@implementation WLUser

+ (NSDictionary*)pictureMapping {
	return @{@"large":@[@"large_avatar_url",@"contributor_large_avatar_url"],
			 @"medium":@[@"medium_avatar_url",@"contributor_medium_avatar_url"],
			 @"small":@[@"small_avatar_url",@"contributor_small_avatar_url"],
			 @"thumbnail":@[@"thumb_avatar_url",@"contributor_small_avatar_url"]};
}

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"phone_number":@"phoneNumber",
									@"country_calling_code":@"countryCallingCode",
									@"dob_in_epoch":@"birthdate",
									@"user_uid":@"identifier",
									@"is_creator":@"isCreator"}];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

- (BOOL)isEqualToUser:(WLUser *)user {
	if (self.identifier.length > 0 && user.identifier.length > 0) {
		return [self.identifier isEqualToString:user.identifier];
	}
	BOOL equalPhoneNumber = [self.phoneNumber isEqualToString:user.phoneNumber];
	BOOL equalBirthdate = [self.birthdate compare:user.birthdate] == NSOrderedSame;
	return equalPhoneNumber && equalBirthdate;
}

+ (EqualityBlock)equalityBlock {
	static EqualityBlock _equalityBlock = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_equalityBlock = ^BOOL(id first, id second) {
			return [first isEqualToUser:second];
		};
	});
	return _equalityBlock;
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
	return [[WLUser currentUser] isEqualToUser:self];
}

@end

@implementation NSArray (WLUser)

- (NSArray*)arrayByAddingCurrentUserAndUser:(WLUser*)user {
	return [[self arrayByAddingUser:user] arrayByAddingCurrentUser];
}

- (NSArray*)arrayByAddingCurrentUser {
	return [self arrayByAddingUser:[WLUser currentUser]];
}

- (NSArray *)arrayByAddingUser:(WLUser *)user {
	if (user) {
		return [self arrayByAddingUniqueObject:user equality:[WLUser equalityBlock]];
	}
	return self;
}

- (NSArray *)arrayByRemovingCurrentUserAndUser:(WLUser *)user {
	NSMutableArray* users = [NSMutableArray array];
	WLUser* currentUser = [WLUser currentUser];
	if (currentUser) {
		[users addObject:currentUser];
	}
	if (user) {
		[users addObject:user];
	}
	return [self arrayByRemovingUsers:users];
}

- (NSArray*)arrayByRemovingCurrentUser {
	return [self arrayByRemovingUser:[WLUser currentUser]];
}

- (NSArray*)arrayByRemovingUser:(WLUser*)user {
	return [self arrayByRemovingUniqueObject:user equality:[WLUser equalityBlock]];
}

- (NSArray*)arrayByRemovingUsers:(NSArray*)users {
	return [self arrayByRemovingUniqueObjects:users equality:[WLUser equalityBlock]];
}

@end
