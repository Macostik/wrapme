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

static NSString* WLSessionPasswordPasteboardName = @"w-a237bcfy580qyr47bdyfq807b3t7r5-l";
static NSString* WLSessionBirthdatePasteboardName = @"w-sdnfvuy7890b4yt9-q8b3t-0yrtv-l";
static NSString* WLSessionUserPasteboardName = @"w-18b-5780897fh340b57n048y38nt348trt34-l";

@implementation WLSession

static WLUser* _user = nil;

+ (UIPasteboard*)pasteboardWithName:(NSString*)name {
    UIPasteboard* pasteboard = [UIPasteboard pasteboardWithName:name create:YES];
	pasteboard.persistent = YES;
    return pasteboard;
}

+ (UIPasteboard*)passwordPasteboard {
	return [self pasteboardWithName:WLSessionPasswordPasteboardName];
}

+ (UIPasteboard*)birthdatePasteboard {
	return [self pasteboardWithName:WLSessionBirthdatePasteboardName];
}

+ (UIPasteboard*)userPasteboard {
	return [self pasteboardWithName:WLSessionUserPasteboardName];
}

+ (WLUser *)user {
	if (!_user) {
		_user = [WLUser unarchive:[[NSUserDefaults standardUserDefaults] objectForKey:WLSessionUserKey]];
	}
	if (!_user) {
		_user = [WLUser unarchive:[[self userPasteboard] valueForPasteboardType:(id)kUTTypeData]];
		if (_user) {
			[_user archive:^(NSData *data) {
				[[NSUserDefaults standardUserDefaults] setObject:data forKey:WLSessionUserKey];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}];
		}
	}
	return _user;
}

+ (void)setUser:(WLUser *)user {
	_user = user;
	if (user) {
		[user archive:^(NSData *data) {
			[[NSUserDefaults standardUserDefaults] setObject:data forKey:WLSessionUserKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
			[[self userPasteboard] setValue:data forPasteboardType:(id)kUTTypeData];
		}];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:WLSessionUserKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[UIPasteboard removePasteboardWithName:WLSessionUserPasteboardName];
	}
}

+ (NSString *)UDID {
	return [OpenUDID value];
}

+ (NSString *)birthdate {
	NSString* birthdate = [[NSUserDefaults standardUserDefaults] stringForKey:WLSessionBirthdateKey];
	if (!birthdate.nonempty) {
		birthdate = [self birthdatePasteboard].string;
		if (birthdate.nonempty) {
			[[NSUserDefaults standardUserDefaults] setObject:birthdate forKey:WLSessionBirthdateKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}
	return birthdate;
}

+ (void)setBirthdate:(NSString *)birthdate {
	[[NSUserDefaults standardUserDefaults] setObject:birthdate forKey:WLSessionBirthdateKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	if (birthdate) {
		[self birthdatePasteboard].string = birthdate;
	} else {
		[UIPasteboard removePasteboardWithName:WLSessionBirthdatePasteboardName];
	}
}

+ (NSString *)password {
	NSString* password = [SSKeychain passwordForService:WLSessionServiceName account:WLSessionAccountName];
	if (!password.nonempty) {
		password = [self passwordPasteboard].string;
		if (password.nonempty) {
			[SSKeychain setPassword:password forService:WLSessionServiceName account:WLSessionAccountName];
		}
	}
	return password;
}

+ (void)setPassword:(NSString *)password {
	[SSKeychain setPassword:password forService:WLSessionServiceName account:WLSessionAccountName];
	if (password) {
		[self passwordPasteboard].string = password;
	} else {
		[UIPasteboard removePasteboardWithName:WLSessionPasswordPasteboardName];
	}
}

+ (BOOL)activated {
	return [self password].nonempty && [self birthdate].nonempty && [self user] != nil;
}

+ (void)clear {
	[self setBirthdate:nil];
	[self setPassword:nil];
	[self setUser:nil];
}

@end
