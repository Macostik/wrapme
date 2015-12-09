//
//  WLAuthorizationRequest.m
//  meWrap
//
//  Created by Ravenpod on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAuthorizationRequest.h"
#import "WLWelcomeViewController.h"
#import "WLUploadingQueue.h"
#import "WLNotificationCenter.h"

@implementation WLAuthorizationRequest

static BOOL authorized = NO;

+ (void)initialize {
    NSHTTPCookie* cookie = [[NSUserDefaults standardUserDefaults] authorizationCookie];
    if (cookie) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        authorized = YES;
    }
}

+ (BOOL)authorized {
    return authorized;
}

+ (BOOL)requiresSignIn {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return !authorized || !defaults.imageURI || !defaults.avatarURI || !defaults.videoURI || ![User currentUser].uid.nonempty;
}

+ (instancetype)signUp:(Authorization*)authorization {
    return [[[[self POST] path:@"users"] parametrize:^(WLAuthorizationRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:authorization.deviceUID forKey:@"device_uid"];
        [parameters trySetObject:authorization.deviceName forKey:@"device_name"];
        [parameters trySetObject:authorization.countryCode forKey:@"country_calling_code"];
        [parameters trySetObject:authorization.phone forKey:@"phone_number"];
        [parameters trySetObject:authorization.email forKey:@"email"];
        NSString *deviceToken = [WLNotificationCenter defaultCenter].pushTokenString;
        if (deviceToken) {
            [parameters trySetObject:deviceToken forKey:@"device_token"];
        }
        parameters[@"os"] = @"ios";
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        success(authorization);
    }];
}

+ (instancetype)activation:(Authorization*)authorization {
    return [[[[self POST] path:@"users/activate"] parametrize:^(WLAuthorizationRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:authorization.deviceUID forKey:@"device_uid"];
        [parameters trySetObject:authorization.deviceName forKey:@"device_name"];
        [parameters trySetObject:authorization.countryCode forKey:@"country_calling_code"];
        [parameters trySetObject:authorization.phone forKey:@"phone_number"];
        [parameters trySetObject:authorization.activationCode forKey:@"activation_code"];
        [parameters trySetObject:authorization.email forKey:@"email"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        authorization.password = [[response.data dictionaryForKey:@"device"] stringForKey:@"password"];
        [authorization setCurrent];
        success(authorization);
    }];
}

+ (instancetype)signIn:(Authorization*)authorization {
    return [[[[[self POST] path:@"users/sign_in"] parametrize:^(WLAuthorizationRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[NSBundle mainBundle].buildVersion forKey:@"app_version"];
        [parameters trySetObject:authorization.deviceUID forKey:@"device_uid"];
        [parameters trySetObject:authorization.countryCode forKey:@"country_calling_code"];
        [parameters trySetObject:authorization.phone forKey:@"phone_number"];
        [parameters trySetObject:authorization.password forKey:@"password"];
        [parameters trySetObject:request.tryUncorfirmedEmail ? authorization.unconfirmed_email : authorization.email forKey:@"email"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        if (!authorized) {
            authorized = YES;
            [WLUploadingQueue start];
        }
        
        for (NSHTTPCookie *cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies) {
            if ([cookie.name isEqualToString:@"_session_id"]) {
                [[NSUserDefaults standardUserDefaults] setAuthorizationCookie:cookie];
            }
        }
		
        id pageSize = response.data[@"pagination_fetch_size"];
        if (pageSize) {
            [NSUserDefaults standardUserDefaults].pageSize = [pageSize integerValue];
        }
		
		if (response.data[@"image_uri"]) {
			[NSUserDefaults standardUserDefaults].imageURI = response.data[@"image_uri"];
        } else {
            [NSUserDefaults standardUserDefaults].imageURI = [Environment currentEnvironment].defaultImageURI;
        }
		
		if (response.data[@"avatar_uri"]) {
			[NSUserDefaults standardUserDefaults].avatarURI = response.data[@"avatar_uri"];
        } else {
            [NSUserDefaults standardUserDefaults].avatarURI = [Environment currentEnvironment].defaultAvatarURI;
        }
        
        if (response.data[@"video_uri"]) {
            [NSUserDefaults standardUserDefaults].videoURI = response.data[@"video_uri"];
        } else {
            [NSUserDefaults standardUserDefaults].videoURI = [Environment currentEnvironment].defaultVideoURI;
        }
		
        NSDictionary* userData = [response.data dictionaryForKey:@"user"];
        
        User *user = [User mappedEntry:userData];
        [authorization updateWithUserData:userData];
        User.currentUser = user;
        [user notifyOnAddition];
        
        if (user.firstTimeUse) {
            [self preloadFirstWrapsWithUser:user];
        }
        
        // code for easily saving test user data
#if TARGET_IPHONE_SIMULATOR
        [WLAuthorizationRequest saveTestUserData:authorization];
#endif
        
        success(user);
    }] validateFailure:^BOOL(WLAuthorizationRequest *request, NSError *error) {
        if([error isResponseError:ResponseCodeNotFoundEntry] && !request.tryUncorfirmedEmail && authorization.unconfirmed_email.nonempty)  {
            request.tryUncorfirmedEmail = YES;
            [request send];
            return NO;
        } else {
            return YES;
        }
    }];
}

+ (instancetype)updateDevice {
    return [[[self PUT] path:@"users/device"] parametrize:^(id request, NSMutableDictionary *parameters) {
        NSString *deviceToken = [WLNotificationCenter defaultCenter].pushTokenString;
        if (deviceToken) {
            WLLog(@"PUBNUB - apns_device_token: %@", deviceToken);
            [parameters trySetObject:deviceToken forKey:@"device_token"];
        }
        parameters[@"os"] = @"ios";
    }];
}

+ (instancetype)signUp {
    return [self signUp:[Authorization currentAuthorization]];
}

+ (instancetype)activation {
    return [self activation:[Authorization currentAuthorization]];
}

+ (instancetype)signIn {
    return [self signIn:[Authorization currentAuthorization]];
}

+ (void)saveTestUserData:(Authorization*)auth {
#ifdef PROJECT_DIR
    NSDictionary *authorizationData = nil;
    if (auth.phone.nonempty && auth.countryCode.nonempty) {
        authorizationData = @{@"phone":auth.phone,@"countryCode":auth.countryCode,@"email":auth.email,@"password":auth.password,@"deviceUID":auth.deviceUID};
    } else {
        authorizationData = @{@"email":auth.email,@"password":auth.password,@"deviceUID":auth.deviceUID};
    }
    
    // replace path to test users plist
    NSString *projectDirectoryPath = PROJECT_DIR;
    NSString *currentTestUsersPath = [projectDirectoryPath stringByAppendingPathComponent:@"meWrap/Resources/Property Lists/Test Users/WLTestUsers.plist"];
    
    NSMutableDictionary *testUsers = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:currentTestUsersPath]];
    
    NSMutableArray *environmentTestUsers = [NSMutableArray arrayWithArray:[testUsers objectForKey:[Environment currentEnvironment].name]];
    
    NSMutableArray *removedUsers = [NSMutableArray array];
    
    for (NSDictionary *testUser in environmentTestUsers) {
        if ([testUser[@"email"] isEqualToString:authorizationData[@"email"]] && [testUser[@"deviceUID"] isEqualToString:authorizationData[@"deviceUID"]]) {
            if ([testUser[@"password"] isEqualToString:authorizationData[@"password"]]) {
                return;
            } else {
                [removedUsers addObject:testUser];
            }
        }
    }
    
    [environmentTestUsers removeObjectsInArray:removedUsers];
    
    [environmentTestUsers addObject:authorizationData];
    
    testUsers[[Environment currentEnvironment].name] = environmentTestUsers;
    
    [testUsers writeToFile:currentTestUsersPath atomically:YES];
#endif
}

+ (void)preloadFirstWrapsWithUser:(User *)user {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[RunQueue fetchQueue] run:^(Block finish) {
            [[PaginatedRequest wraps:nil] fresh:^(NSArray *array) {
                NSArray *wraps = [user sortedWraps];
                if (wraps.count > 0) {
                    [wraps enumerateObjectsUsingBlock:^(Wrap *wrap, NSUInteger idx, BOOL *stop) {
                        [wrap preload];
                        if (idx == 2) *stop = YES;
                    }];
                }
                finish();
            } failure:^(NSError *error) {
                finish();
            }];
        }];
    });
}

+ (instancetype)whois:(NSString *)email {
    return [[[[self GET] path:@"users/whois"] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:email forKey:@"email"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        WLWhoIs* whoIs = [WLWhoIs sharedInstance];
        NSDictionary *userInfo = [response.data dictionaryForKey:@"user"];
        whoIs.found = [[userInfo numberForKey:@"found"] boolValue];
        whoIs.confirmed = [[userInfo numberForKey:@"confirmed_email"] boolValue];
        NSString* userUID = [User uid:userInfo];
        if (userUID.nonempty) {
            User *user = (User*)[User entry:userUID];
            User.currentUser = user;
            [user notifyOnAddition];
        }
        Authorization* authorization = [[Authorization alloc] init];
        authorization.email = email;
        if (!whoIs.confirmed) {
            authorization.unconfirmed_email = email;
        }
        [authorization setCurrent];
        NSString *deviceUID = authorization.deviceUID;
        NSArray* devices = [userInfo arrayForKey:@"device_uids"];
        if (devices.count == 0 || (devices.count == 1 && [devices[0][@"device_uid"] isEqualToString:deviceUID])) {
            whoIs.requiresApproving = NO;
        } else {
            whoIs.requiresApproving = YES;
            whoIs.containsPhoneDevice = NO;
            for (NSDictionary *device in devices) {
                if (![device[@"device_uid"] isEqualToString:deviceUID] && [device[@"full_phone_number"] nonempty]) {
                    whoIs.containsPhoneDevice = YES;
                    break;
                }
            }
        }
        success(whoIs);
    }];
}

+ (instancetype)linkDevice:(NSString*)passcode {
    return [[[[self POST] path:@"users/link_device"] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[Authorization currentAuthorization].email forKey:@"email"];
        [parameters trySetObject:[Authorization currentAuthorization].deviceUID forKey:@"device_uid"];
        [parameters trySetObject:passcode forKey:@"approval_code"];
    }] parse:^(Response *response, ObjectBlock success, FailureBlock failure) {
        Authorization *authorization = [Authorization currentAuthorization];
        authorization.password = [[response.data dictionaryForKey:@"device"] stringForKey:@"password"];
        [authorization setCurrent];
        success(authorization);
    }];
}

- (BOOL)skipReauthorizing {
    return YES;
}

@end

@implementation Authorization (WLAuthorizationRequest)

- (id)signUp:(ObjectBlock)success failure:(FailureBlock)failure {
    return [[WLAuthorizationRequest signUp:self] send:success failure:failure];
}

- (id)activate:(ObjectBlock)success failure:(FailureBlock)failure {
    return [[WLAuthorizationRequest activation:self] send:success failure:failure];
}

- (id)signIn:(ObjectBlock)success failure:(FailureBlock)failure {
	return [[WLAuthorizationRequest signIn:self] send:success failure:failure];
}

@end

@implementation WLWhoIs

+ (instancetype)sharedInstance {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

@end

