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
#import "WLAuthorization.h"
#import "WLNotificationBroadcaster.h"

static NSString* WLSessionServiceName = @"WrapLive";
static NSString* WLSessionAccountName = @"WrapLiveAccount";
static NSString* WLSessionUserKey = @"WrapLiveUser";
static NSString* WLSessionAuthorizationKey = @"WrapLiveAuthorization";
static NSString* WLSessionPhoneNumberKey = @"WrapLivePhoneNumber";
static NSString* WLSessionCountryCallingCodeKey = @"WrapLiveCountryCallingCode";
static NSString* WLSessionEmailKey = @"WLSessionEmailKey";
static NSString* WLSessionDeviceTokenKey = @"WrapLiveDeviceToken";

@implementation WLSession

static WLAuthorization* _authorization = nil;

+ (WLAuthorization *)authorization {
	if (!_authorization) {
		_authorization = [WLAuthorization unarchive:[[NSUserDefaults standardUserDefaults] objectForKey:WLSessionAuthorizationKey]];
	}
	return _authorization;
}

+ (void)setAuthorization:(WLAuthorization *)authorization {
	_authorization = authorization;
	if (authorization) {
		[authorization archive:^(NSData *data) {
			[[NSUserDefaults standardUserDefaults] setObject:data forKey:WLSessionAuthorizationKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:WLSessionAuthorizationKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

+ (NSString *)UDID {
	return [OpenUDID value];
}

+ (void)clear {
	[self setAuthorization:nil];
}

static NSData* _deviceToken = nil;

+ (NSData *)deviceToken {
	if (!_deviceToken) {
		_deviceToken = [[NSUserDefaults standardUserDefaults] dataForKey:WLSessionDeviceTokenKey];
	}
	return _deviceToken;
}

+ (void)setDeviceToken:(NSData *)deviceToken {
	_deviceToken = deviceToken;
	if (deviceToken) {
		[[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:WLSessionDeviceTokenKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

@end
