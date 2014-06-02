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

@implementation WLAuthorization

- (NSString *)deviceUID {
	if (!_deviceUID) {
		_deviceUID = [WLSession UDID];
	}
	return _deviceUID;
}

- (BOOL)canAuthorize {
	return self.countryCode.nonempty && self.phone.nonempty && self.email.nonempty && self.password.nonempty;
}

- (NSString *)fullPhoneNumber {
	return [NSString stringWithFormat:@"+%@ %@", self.countryCode, self.phone];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

@end

@implementation WLAuthorization (CurrentAuthorization)

+ (WLAuthorization*)currentAuthorization {
	return [WLSession authorization];
}

+ (void)setCurrentAuthorization:(WLAuthorization*)authorization {
	[WLSession setAuthorization:authorization];
}

- (void)setCurrent {
	[WLAuthorization setCurrentAuthorization:self];
}

@end
