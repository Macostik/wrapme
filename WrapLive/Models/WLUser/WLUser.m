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
#import "NSArray+Additions.h"

@implementation WLUser

+ (NSDictionary*)pictureMapping {
	return @{@"large":@[@"large_avatar_url",@"contributor_large_avatar_url"],
			 @"medium":@[@"medium_avatar_url",@"contributor_medium_avatar_url"],
			 @"small":@[@"small_avatar_url",@"contributor_small_avatar_url"],
			 @"thumbnail":@[@"thumb_avatar_url",@"contributor_small_avatar_url"]};
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
	self = [super initWithDictionary:dict error:err];
	if (self) {
		self.registrationCompleted = ![[dict objectForKey:@"avatar_file_size"] isKindOfClass:[NSNull class]] && ![[dict objectForKey:@"name"] isKindOfClass:[NSNull class]];
	}
	return self;
}

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"phone_number":@"phoneNumber",
									@"country_calling_code":@"countryCallingCode",
									@"dob_in_epoch":@"birthdate",
									@"user_uid":@"identifier"}];
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

+ (NSArray *)removeCurrentUserFromArray:(NSArray *)users {
	return [users arrayByRemovingUniqueObject:[WLUser currentUser] equality:^BOOL(id first, id second) {
		return [first isEqualToUser:second];
	}];
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