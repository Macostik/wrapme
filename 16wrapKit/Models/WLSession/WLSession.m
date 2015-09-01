//
//  WLSession.m
//  moji
//
//  Created by Ravenpod on 21.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSession.h"
#import "OpenUDID.h"
#import "WLUser.h"
#import "NSString+Additions.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLAuthorization.h"
#import "WLNotificationCenter.h"
#import "WLEntryManager.h"
#import "WLCryptographer.h"
#import "NSUserDefaults+WLAppGroup.h"
#import "NSObject+Extension.h"
#import "NSBundle+Extended.h"

static NSString* WLSessionAuthorizationKey = @"WrapLiveAuthorization";
static NSString* WLSessionPhoneNumberKey = @"WrapLivePhoneNumber";
static NSString* WLSessionCountryCallingCodeKey = @"WrapLiveCountryCallingCode";
static NSString* WLSessionEmailKey = @"WLSessionEmailKey";
static NSString* WLSessionDeviceTokenKey = @"WrapLiveDeviceToken";
static NSString* WLSessionConfirmationKey = @"WLSessionConfirmationConditions";
static NSString* WLSessionAppVersionKey = @"wrapLiveVersion";
static NSString* WLSessionServerTimeDifference = @"WLServerTimeDifference";

@implementation NSUserDefaults (WLSessionData)

// MARK: - authorization

static WLAuthorization* _authorization = nil;

- (WLAuthorization *)authorization {
    if (!_authorization) {
        NSData *data = [[NSUserDefaults appGroupUserDefaults] objectForKey:WLAppGroupEncryptedAuthorization];
        if (data) {
            data = [WLCryptographer decryptData:data];
        } else {
            data = [self objectForKey:WLSessionAuthorizationKey];
        }
        _authorization = [WLAuthorization unarchive:data];
    }
    return _authorization;
}

- (void)setAuthorization:(WLAuthorization *)authorization {
    _authorization = authorization;
    NSUserDefaults *userDefaults = [NSUserDefaults appGroupUserDefaults];
    if (authorization) {
        [authorization archive:^(NSData *data) {
            NSData *encryptedData = [WLCryptographer encryptData:data];
            [userDefaults setObject:encryptedData forKey:WLAppGroupEncryptedAuthorization];
            [self setObject:encryptedData forKey:WLAppGroupEncryptedAuthorization];
        }];
    } else {
        [userDefaults setObject:nil forKey:WLAppGroupEncryptedAuthorization];
        [self setObject:nil forKey:WLAppGroupEncryptedAuthorization];
    }
    [userDefaults synchronize];
    [self enqueueSynchronize];
}

// MARK: - authorizationCookie

- (NSHTTPCookie*)authorizationCookie {
    NSDictionary *cookieProperties = [self dictionaryForKey:@"authorizationCookie"];
    if (cookieProperties) {
        return [NSHTTPCookie cookieWithProperties:cookieProperties];
    }
    return nil;
}

- (void)setAuthorizationCookie:(NSHTTPCookie*)authorizationCookie {
    [self setObject:authorizationCookie.properties forKey:@"authorizationCookie"];
    [self enqueueSynchronize];
}

// MARK: - UDID

- (NSString *)UDID {
	return [OpenUDID value];
}

// MARK: - deviceToken

static NSData* _deviceToken = nil;

- (NSData *)deviceToken {
	if (!_deviceToken) {
		_deviceToken = [self dataForKey:WLSessionDeviceTokenKey];
	}
	return _deviceToken;
}

- (void)setDeviceToken:(NSData *)deviceToken {
	_deviceToken = deviceToken;
	[self setObject:deviceToken forKey:WLSessionDeviceTokenKey];
    [self enqueueSynchronize];
}

// MARK: - confirmationDate

static NSDate *_confirmationDate = nil;

- (NSDate *)confirmationDate {
    if (!_confirmationDate) {
        _confirmationDate = [self objectForKey:WLSessionConfirmationKey];
    }
    return _confirmationDate;
}

- (void)setConfirmationDate:(NSDate *)confirmationDate {
    _confirmationDate = confirmationDate;
    [self setObject:confirmationDate forKey:WLSessionConfirmationKey];
    [self enqueueSynchronize];
}

// MARK: - appVersion

- (NSString *)appVersion {
    return [self stringForKey:WLSessionAppVersionKey];
}

- (void)setAppVersion:(NSString *)version {
    [self setObject:version forKey:WLSessionAppVersionKey];
    [self enqueueSynchronize];
}

// MARK: - numberOfLaunches

- (NSUInteger)numberOfLaunches {
    return [self integerForKey:@"WLNumberOfLaucnhes"];
}

- (void)setNumberOfLaunches:(NSUInteger)numberOfLaunches {
    [self setInteger:numberOfLaunches forKey:@"WLNumberOfLaucnhes"];
    [self enqueueSynchronize];
}

// MARK: - serverTimeDifference

static NSTimeInterval _difference = 0;

- (NSTimeInterval)serverTimeDifference {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _difference = [self doubleForKey:WLSessionServerTimeDifference];
    });
    return _difference;
}

- (void)setServerTimeDifference:(NSTimeInterval)interval {
    if (_difference != interval) {
        _difference = interval;
        [self setDouble:interval forKey:WLSessionServerTimeDifference];
        [self enqueueSynchronize];
    }
}

// MARK: - cameraDefaultPosition

- (NSNumber*)cameraDefaultPosition {
    return [self objectForKey:@"WLCameraDefaultPosition"];
}

- (void)setCameraDefaultPosition:(NSNumber*)cameraDefaultPosition {
    [self setObject:cameraDefaultPosition forKey:@"WLCameraDefaultPosition"];
    [self enqueueSynchronize];
}

// MARK: - cameraDefaultFlashMode

- (NSNumber*)cameraDefaultFlashMode {
    return [self objectForKey:@"WLCameraDefaultFlashMode"];
}

- (void)setCameraDefaultFlashMode:(NSNumber*)cameraDefaultFlashMode {
    [self setObject:cameraDefaultFlashMode forKey:@"WLCameraDefaultFlashMode"];
    [self enqueueSynchronize];
}

// MARK: - shownHints

- (NSMutableDictionary *)shownHints {
    NSMutableDictionary *shownHints = [self objectForKey:@"WLHintView_shownHints"];
    if (!shownHints) {
        self.shownHints = shownHints = [NSMutableDictionary dictionary];
    } else {
        shownHints = [shownHints mutableCopy];
    }
    return shownHints;
}

- (void)setShownHints:(NSMutableDictionary *)shownHints {
    [self setObject:shownHints forKey:@"WLHintView_shownHints"];
    [self enqueueSynchronize];
}

// MARK: - historyDate

static NSDate *_historyDate;

- (NSDate *)historyDate {
    if (!_historyDate) _historyDate = [self objectForKey:@"historyDate"];
    return _historyDate;
}

- (void)setHistoryDate:(NSDate *)historyDate {
    _historyDate = historyDate;
    [self setObject:historyDate forKey:@"historyDate"];
    [self enqueueSynchronize];
}

// MARK: - handledNotifications

static NSOrderedSet *_handledNotifications;

- (NSOrderedSet *)handledNotifications {
    if (!_handledNotifications) {
        _handledNotifications = [NSOrderedSet orderedSetWithArray:[self objectForKey:@"handledNotifications"]];
    }
    return _handledNotifications;
}

- (void)setHandledNotifications:(NSOrderedSet *)handledNotifications {
    _handledNotifications = handledNotifications;
    [self setObject:[_handledNotifications array] forKey:@"handledNotifications"];
    [self enqueueSynchronize];
}

// MARK: - recentEmojis

- (NSArray *)recentEmojis {
    return [self arrayForKey:@"recentEmojis"];
}

- (void)setRecentEmojis:(NSArray *)recentEmojis {
    [self setObject:recentEmojis forKey:@"recentEmojis"];
    [self enqueueSynchronize];
}

// MARK: - imageURI

static NSString *_imageURI = nil;

- (NSString *)imageURI {
    if (!_imageURI) {
        _imageURI = [self stringForKey:@"imageURI"];
        if (!_imageURI) {
            _imageURI = @"https://d2rojtzyvje8rl.cloudfront.net/candies/image_attachments";
        }
    }
    return _imageURI;
}

- (void)setImageURI:(NSString *)imageURI {
    _imageURI = imageURI;
    [self setObject:imageURI forKey:@"imageURI"];
    [self enqueueSynchronize];
}

// MARK: - avatarURI

static NSString *_avatarURI = nil;

- (NSString *)avatarURI {
    if (!_avatarURI) {
        _avatarURI = [self stringForKey:@"avatarURI"];
        if (!_avatarURI) {
            _avatarURI = @"https://d2rojtzyvje8rl.cloudfront.net/users/avatars";
        }
    }
    return _avatarURI;
}

- (void)setAvatarURI:(NSString *)avatarURI {
    _avatarURI = avatarURI;
    [self setObject:avatarURI forKey:@"avatarURI"];
    [self enqueueSynchronize];
}

// MARK: - methods

- (void)setCurrentAppVersion {
    self.appVersion = NSMainBundle.buildVersion;
}

- (void)clear {
    [WLUser setCurrentUser:nil];
    [self setAuthorization:nil];
    [self setAuthorizationCookie:nil];
    [[WLEntryManager manager] clear];
}

- (void)enqueueSynchronize {
    [self enqueueSelectorPerforming:@selector(synchronize)];
}

@end
