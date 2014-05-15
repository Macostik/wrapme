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
#import "NSString+Additions.h"
#import <MobileCoreServices/MobileCoreServices.h>

static NSString* WLSessionServiceName = @"WrapLive";
static NSString* WLSessionAccountName = @"WrapLiveAccount";
static NSString* WLSessionUserKey = @"WrapLiveUser";
static NSString* WLSessionPhoneNumberKey = @"WrapLivePhoneNumber";
static NSString* WLSessionCountryCallingCodeKey = @"WrapLiveCountryCallingCode";
static NSString* WLSessionBirthdateKey = @"WrapLiveBirthdate";
static NSString* WLSessionDeviceTokenKey = @"WrapLiveDeviceToken";

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
	NSString* birthdate = [[NSUserDefaults standardUserDefaults] stringForKey:WLSessionBirthdateKey];
	return birthdate;
}

+ (void)setBirthdate:(NSString *)birthdate {
	[[NSUserDefaults standardUserDefaults] setObject:birthdate forKey:WLSessionBirthdateKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)password {
	NSString* password = [SSKeychain passwordForService:WLSessionServiceName account:WLSessionAccountName];
	return password;
}

+ (void)setPassword:(NSString *)password {
	[SSKeychain setPassword:password forService:WLSessionServiceName account:WLSessionAccountName];
}

+ (BOOL)activated {
	return [self password].nonempty && [self birthdate].nonempty && [self user] != nil;
}

+ (void)clear {
	[self setBirthdate:nil];
	[self setPassword:nil];
	[self setUser:nil];
}

+ (NSData *)deviceToken {
	return [[NSUserDefaults standardUserDefaults] dataForKey:WLSessionDeviceTokenKey];
}

+ (void)setDeviceToken:(NSData *)deviceToken {
	[[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:WLSessionDeviceTokenKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
