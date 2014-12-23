//
//  WLAuthorization.m
//  WrapLive
//
//  Created by Sergey Maximenko on 21.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAuthorization.h"
#import "NSString+Additions.h"
#import "WLSession.h"
#import "WLEntryKeys.h"
#import "UIDevice-Hardware.h"
#import "WLCryptographer.h"
#import "NSDictionary+Extended.h"
#import "WLTelephony.h"

static NSString *const WLUserDefaultsExtensionKey = @"group.com.ravenpod.wraplive";
static NSString *const WLExtensionWrapKey = @"WLExtansionWrapKey";

@implementation WLAuthorization

+ (NSArray *)archivableProperties {
    return @[@"deviceUID",@"deviceName",@"countryCode",@"phone",@"email",@"unconfirmed_email",@"password"];
}

- (NSString *)deviceUID {
	if (!_deviceUID) {
		_deviceUID = [WLSession UDID];
	}
	return _deviceUID;
}

- (NSString *)deviceName {
    if (!_deviceName) {
        _deviceName = [UIDevice currentDevice].modelName;
    }
    return _deviceName;
}

- (BOOL)canSignUp {
    return self.email.nonempty;
}

- (BOOL)canAuthorize {
	return self.canSignUp && self.password.nonempty;
}

- (NSString *)fullPhoneNumber {
	return [NSString stringWithFormat:@"+%@ %@", self.countryCode, self.formattedPhone ? : self.phone];
}

- (void)updateWithUserData:(NSDictionary *)userData {
    if ([userData objectForKey:WLEmailKey]) self.email = [userData stringForKey:WLEmailKey];
    if ([userData objectForKey:WLUnconfirmedEmail]) self.unconfirmed_email = [userData stringForKey:WLUnconfirmedEmail];
    [self setCurrent];
}

@end

@implementation WLAuthorization (CurrentAuthorization)

+ (WLAuthorization*)currentAuthorization {
	return [WLSession authorization];
}

+ (void)setCurrentAuthorization:(WLAuthorization*)authorization {
	[WLSession setAuthorization:authorization];
    [self parseExtensionAutorization:authorization];
}

+ (NSString *)priorityEmail {
    WLAuthorization *autorization = [WLAuthorization currentAuthorization];
    return [autorization unconfirmed_email].nonempty ? autorization.unconfirmed_email : autorization.email;
}

- (void)setCurrent {
	[WLAuthorization setCurrentAuthorization:self];
}

#pragma mark - WLExtension halper

+ (void)parseExtensionAutorization:(WLAuthorization *)autorization {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:WLUserDefaultsExtensionKey];
    NSMutableDictionary *attDictionary = [NSMutableDictionary dictionaryWithCapacity:5.0];
    [attDictionary trySetObject:autorization.deviceUID forKey:WLDeviceIDKey];
    [attDictionary trySetObject:autorization.countryCode forKey:WLCountryCodeKey];
    [attDictionary trySetObject:autorization.phone forKey:WLPhoneKey];
    [attDictionary trySetObject:autorization.email forKey:WLEmailKey];
    NSString *environmentName = [[[NSBundle mainBundle] infoDictionary] stringForKey:WLEnvironment];
    [attDictionary trySetObject:environmentName forKey:WLEnvironment];
    NSData *passwordData = [WLCryptographer encrypt:autorization.password];
    [attDictionary setObject:passwordData forKey:WLPasswordKey];
    [userDefaults setObject:attDictionary forKey:WLExtensionWrapKey];
    BOOL success = [userDefaults synchronize];
    NSLog(@"notifcashion passed success - %@", success? @"YES" : @"NO");
}


@end
