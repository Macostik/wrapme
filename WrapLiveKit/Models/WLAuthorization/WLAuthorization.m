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
#import "UIFont+CustomFonts.h"

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
}

+ (NSString *)priorityEmail {
    WLAuthorization *autorization = [WLAuthorization currentAuthorization];
    return [autorization unconfirmed_email].nonempty ? autorization.unconfirmed_email : autorization.email;
}

- (void)setCurrent {
	[WLAuthorization setCurrentAuthorization:self];
}

#pragma mark - WLExtension halper

+ (NSAttributedString *)attributedVerificationSuggestion {
    NSString *email = [[self currentAuthorization] unconfirmed_email];
    NSMutableAttributedString *emailVerificationString = [[NSMutableAttributedString alloc] initWithString:
                                                          [[NSString alloc] initWithFormat:WLLS(@"verification email %@"), email]];
    NSRange fullRange = NSMakeRange(0, emailVerificationString.length);
    NSRange bitRange = [emailVerificationString.string rangeOfString:email];
    [emailVerificationString setAttributes:@{NSFontAttributeName:[UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetXSmall]}
                                     range:fullRange];
    [emailVerificationString setAttributes:@{NSFontAttributeName:[UIFont preferredFontWithName:WLFontOpenSansRegular preset:WLFontPresetXSmall]}
                                     range:bitRange];
    return emailVerificationString;
}


@end
