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

@implementation WLAuthorization

- (NSString *)deviceUID {
	if (!_deviceUID) {
		_deviceUID = [WLSession UDID];
	}
	return _deviceUID;
}

- (NSString *)deviceName {
    if (!_deviceName) {
        _deviceName = [UIDevice currentDevice].model;
    }
    return _deviceName;
}

- (BOOL)canAuthorize {
	return self.countryCode.nonempty && self.phone.nonempty && self.email.nonempty && self.password.nonempty;
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
}

+ (NSString *)priorityEmail {
    WLAuthorization *autorization = [WLAuthorization currentAuthorization];
    return [autorization unconfirmed_email].nonempty ? autorization.unconfirmed_email : autorization.email;
}

- (void)setCurrent {
	[WLAuthorization setCurrentAuthorization:self];
}

@end
