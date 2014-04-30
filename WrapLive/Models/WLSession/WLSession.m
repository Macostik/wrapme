//
//  WLSession.m
//  WrapLive
//
//  Created by Sergey Maximenko on 21.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLSession.h"
#import <SSKeychain/SSKeychain.h>
#import <OpenUDID/OpenUDID.h>
#import "WLUser.h"

static NSString* WLSessionServiceName = @"WrapLive";
static NSString* WLSessionAccountName = @"WrapLiveAccount";
static NSString* WLSessionUserKey = @"WrapLiveUser";
static NSString* WLSessionPhoneNumberKey = @"WrapLivePhoneNumber";
static NSString* WLSessionCountryCallingCodeKey = @"WrapLiveCountryCallingCode";
static NSString* WLSessionBirthdateKey = @"WrapLiveBirthdate";

@implementation WLSession

static WLUser* _user = nil;

+ (WLUser *)user {
	if (!_user) {
		_user = [WLUser unarchive:[[NSUserDefaults standardUserDefaults] objectForKey:WLSessionUserKey]];
	}
	return _user;
}

+ (void)setUser:(WLUser *)user {
	_user = user;
	if (user) {
		[user archive:^(NSData *data) {
			[[NSUserDefaults standardUserDefaults] setObject:data forKey:WLSessionUserKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:WLSessionUserKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

+ (NSString *)UDID {
	return [OpenUDID value];
}

+ (NSString *)birthdate {
	return [[NSUserDefaults standardUserDefaults] stringForKey:WLSessionBirthdateKey];
}

+ (void)setBirthdate:(NSString *)birthdate {
	[[NSUserDefaults standardUserDefaults] setObject:birthdate forKey:WLSessionBirthdateKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)password {
	return [SSKeychain passwordForService:WLSessionServiceName account:WLSessionAccountName];
}

+ (void)setPassword:(NSString *)password {
	[SSKeychain setPassword:password forService:WLSessionServiceName account:WLSessionAccountName];
}

+ (BOOL)activated {
	return [self password].length > 0 && [self birthdate].length > 0 && [self user] != nil;
}

@end
