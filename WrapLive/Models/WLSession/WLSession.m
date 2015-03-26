//
//  WLSession.m
//  WrapLive
//
//  Created by Sergey Maximenko on 21.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLSession.h"
#import <OpenUDID/OpenUDID.h>
#import "WLUser.h"
#import "NSString+Additions.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLAuthorization.h"
#import "WLNotificationCenter.h"
#import "WLEntryManager.h"
#import "WLCryptographer.h"
#import "NSUserDefaults+WLAppGroup.h"

static NSString* WLSessionServiceName = @"WrapLive";
static NSString* WLSessionAccountName = @"WrapLiveAccount";
static NSString* WLSessionUserKey = @"WrapLiveUser";
static NSString* WLSessionAuthorizationKey = @"WrapLiveAuthorization";
static NSString* WLSessionPhoneNumberKey = @"WrapLivePhoneNumber";
static NSString* WLSessionCountryCallingCodeKey = @"WrapLiveCountryCallingCode";
static NSString* WLSessionEmailKey = @"WLSessionEmailKey";
static NSString* WLSessionDeviceTokenKey = @"WrapLiveDeviceToken";
static NSString* WLSessionConfirmationKey = @"WLSessionConfirmationConditions";
static NSString* WLSessionAppVersionKey = @"wrapLiveVersion";

@implementation WLSession

+ (void)initialize {
    [super initialize];
    WLUserDefaults = [NSUserDefaults standardUserDefaults];
}

static WLAuthorization* _authorization = nil;

+ (WLAuthorization *)authorization {
    if (!_authorization) {
        _authorization = [WLAuthorization unarchive:[WLCryptographer decryptData:[[NSUserDefaults appGroupUserDefaults] objectForKey:WLAppGroupEncryptedAuthorization]]];
    }
    if (!_authorization) {
        _authorization = [[WLAuthorization alloc] init];
    }
    return _authorization;
}

+ (void)setAuthorization:(WLAuthorization *)authorization {
    _authorization = authorization;
    if (authorization) {
        [authorization archive:^(NSData *data) {
            NSUserDefaults *userDefaults = [NSUserDefaults appGroupUserDefaults];
            [userDefaults setObject:[WLCryptographer encryptData:data] forKey:WLAppGroupEncryptedAuthorization];
            [userDefaults synchronize];
        }];
    } else {
        [self setObject:nil key:WLSessionAuthorizationKey];
    }
}

+ (NSString *)UDID {
	return [OpenUDID value];
}

+ (void)clear {
    [WLUser setCurrentUser:nil];
	[self setAuthorization:nil];
    [[WLEntryManager manager] clear];
}

static NSData* _deviceToken = nil;
static NSDate *_confirmationDate = nil;

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

+ (NSDate *)confirmationDate {
    if (!_confirmationDate) {
        _confirmationDate = [WLUserDefaults objectForKey:WLSessionConfirmationKey];
    }
    return _confirmationDate;
}

+ (void)setConfirmationDate:(NSDate *)confirmationDate {
    _confirmationDate = confirmationDate;
    [WLUserDefaults setObject:confirmationDate forKey:WLSessionConfirmationKey];
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

+ (NSString *)appVersion {
    return [self object:WLSessionAppVersionKey];
}

+ (void)setAppVersion:(NSString *)version {
    [self setObject:version key:WLSessionAppVersionKey];
}

+ (void)setCurrentAppVersion {
    NSString* currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self setAppVersion:currentVersion];
}

+ (NSUInteger)numberOfLaunches {
    return [self integer:@"WLNumberOfLaucnhes"];
}

+ (void)setNumberOfLaunches:(NSUInteger)numberOfLaunches {
    [self setInteger:numberOfLaunches key:@"WLNumberOfLaucnhes"];
}

@end
