//
//  WLUser.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUser.h"
#import "NSDate+Formatting.h"
#import "NSDictionary+Extended.h"
#import "WLSession.h"

@implementation WLUser

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
	self = [super initWithDictionary:dict error:err];
	if (self) {
		self.registrationCompleted = ![[dict objectForKey:@"avatar_file_size"] isKindOfClass:[NSNull class]] && ![[dict objectForKey:@"name"] isKindOfClass:[NSNull class]];
	}
	return self;
}

+ (NSMutableDictionary *)mapping {
	NSMutableDictionary* mapping = [super mapping];
	[mapping addEntriesFromDictionary:@{@"phone_number":@"phoneNumber",
										@"country_calling_code":@"countryCallingCode",
										@"dob_in_epoch":@"birthdate",
										@"user_uid":@"identifier"}];
	return mapping;
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