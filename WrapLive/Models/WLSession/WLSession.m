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
#import "WLNotificationCenter.h"

static NSString* WLSessionServiceName = @"WrapLive";
static NSString* WLSessionAccountName = @"WrapLiveAccount";
static NSString* WLSessionUserKey = @"WrapLiveUser";
static NSString* WLSessionAuthorizationKey = @"WrapLiveAuthorization";
static NSString* WLSessionPhoneNumberKey = @"WrapLivePhoneNumber";
static NSString* WLSessionCountryCallingCodeKey = @"WrapLiveCountryCallingCode";
static NSString* WLSessionEmailKey = @"WLSessionEmailKey";
static NSString* WLSessionDeviceTokenKey = @"WrapLiveDeviceToken";

@implementation WLSession

+ (void)initialize {
    [super initialize];
    WLUserDefaults = [NSUserDefaults standardUserDefaults];
}

static WLAuthorization* _authorization = nil;

+ (WLAuthorization *)authorization {
	if (!_authorization) {
		_authorization = [WLAuthorization unarchive:[self object:WLSessionAuthorizationKey]];
	}
	return _authorization;
}

+ (void)setAuthorization:(WLAuthorization *)authorization {
	_authorization = authorization;
	if (authorization) {
		[authorization archive:^(NSData *data) {
			[self setObject:data key:WLSessionAuthorizationKey];
		}];
	} else {
		[self setObject:nil key:WLSessionAuthorizationKey];
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
		_deviceToken = [WLUserDefaults dataForKey:WLSessionDeviceTokenKey];
	}
	return _deviceToken;
}

+ (void)setDeviceToken:(NSData *)deviceToken {
	_deviceToken = deviceToken;
	[WLUserDefaults setObject:deviceToken forKey:WLSessionDeviceTokenKey];
    [self synchronize];
}

+ (void)setObject:(id)o key:(NSString *)k {
    [WLUserDefaults setObject:o forKey:k];
    [self synchronize];
}

+ (void)setDouble:(double)d key:(NSString *)k {
    [WLUserDefaults setDouble:d forKey:k];
    [self synchronize];
}

+ (void)setInteger:(NSInteger)i key:(NSString *)k {
    [WLUserDefaults setInteger:i forKey:k];
    [self synchronize];
}

+ (id)object:(NSString*)k {
    return [WLUserDefaults objectForKey:k];
}

+ (double)wl_double:(NSString*)k {
    return [WLUserDefaults doubleForKey:k];
}

+ (NSInteger)integer:(NSString*)k {
    return [WLUserDefaults integerForKey:k];
}

+ (void)synchronize {
    [NSObject cancelPreviousPerformRequestsWithTarget:WLUserDefaults selector:_cmd object:nil];
    [WLUserDefaults performSelector:_cmd withObject:nil afterDelay:0.5f];
}

@end
