//
//  WLAuthorizationRequest.m
//  moji
//
//  Created by Ravenpod on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAuthorizationRequest.h"
#import "WLWelcomeViewController.h"
#import "WLUploadingQueue.h"
#import "WLOperationQueue.h"

@implementation WLAuthorizationRequest

static BOOL authorized = NO;

+ (void)initialize {
    NSHTTPCookie* cookie = [WLSession authorizationCookie];
    if (cookie) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        authorized = YES;
    }
}

+ (BOOL)authorized {
    return authorized;
}

+ (instancetype)signUp:(WLAuthorization*)authorization {
    return [[[self POST:@"users"] parametrize:^(WLAuthorizationRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:authorization.deviceUID forKey:@"device_uid"];
        [parameters trySetObject:authorization.deviceName forKey:@"device_name"];
        [parameters trySetObject:authorization.countryCode forKey:@"country_calling_code"];
        [parameters trySetObject:authorization.phone forKey:@"phone_number"];
        [parameters trySetObject:authorization.email forKey:@"email"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        success(authorization);
    }];
}

+ (instancetype)activation:(WLAuthorization*)authorization {
    return [[[self POST:@"users/activate"] parametrize:^(WLAuthorizationRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:authorization.deviceUID forKey:@"device_uid"];
        [parameters trySetObject:authorization.deviceName forKey:@"device_name"];
        [parameters trySetObject:authorization.countryCode forKey:@"country_calling_code"];
        [parameters trySetObject:authorization.phone forKey:@"phone_number"];
        [parameters trySetObject:authorization.activationCode forKey:@"activation_code"];
        [parameters trySetObject:authorization.email forKey:@"email"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        authorization.password = [[response.data dictionaryForKey:@"device"] stringForKey:@"password"];
        [authorization setCurrent];
        success(authorization);
    }];
}

+ (instancetype)signIn:(WLAuthorization*)authorization {
    return [[[[self POST:@"users/sign_in"] parametrize:^(WLAuthorizationRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:authorization.deviceUID forKey:@"device_uid"];
        [parameters trySetObject:authorization.countryCode forKey:@"country_calling_code"];
        [parameters trySetObject:authorization.phone forKey:@"phone_number"];
        [parameters trySetObject:authorization.password forKey:@"password"];
        [parameters trySetObject:request.tryUncorfirmedEmail ? authorization.unconfirmed_email : authorization.email forKey:@"email"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (!authorized) {
            authorized = YES;
            [WLUploadingQueue start];
        }
        
        for (NSHTTPCookie *cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies) {
            if ([cookie.name isEqualToString:@"_session_id"]) {
                [WLSession setAuthorizationCookie:cookie];
            }
        }
        
        id pageSize = [response.data objectForKey:@"pagination_fetch_size"];
        if (pageSize) {
            WLConstants.pageSize = [pageSize integerValue];
        }
        
        NSDictionary* userData = [response.data dictionaryForKey:@"user"];
        
        WLUser* user = [WLUser API_entry:userData];
        [authorization updateWithUserData:userData];
        [user setCurrent];
        
        if (user.firstTimeUse) {
            [self preloadFirstWrapsWithUser:user];
        }
        
        // code for easily saving test user data
#if TARGET_IPHONE_SIMULATOR
        [WLAuthorizationRequest saveTestUserData:authorization];
#endif
        
        success(user);
    }] validateFailure:^BOOL(WLAuthorizationRequest *request, NSError *error) {
        if([error isError:WLErrorNotFoundEntry] && !request.tryUncorfirmedEmail && authorization.unconfirmed_email.nonempty)  {
            request.tryUncorfirmedEmail = YES;
            [request send];
            return NO;
        } else {
            return YES;
        }
    }];
}

+ (instancetype)signUp {
    return [self signUp:[WLAuthorization currentAuthorization]];
}

+ (instancetype)activation {
    return [self activation:[WLAuthorization currentAuthorization]];
}

+ (instancetype)signIn {
    return [self signIn:[WLAuthorization currentAuthorization]];
}

+ (void)saveTestUserData:(WLAuthorization*)auth {
#ifdef WRAPLIVE_PROJECT_DIR
    NSDictionary *authorizationData = nil;
    if (auth.phone.nonempty && auth.countryCode.nonempty) {
        authorizationData = @{@"phone":auth.phone,@"countryCode":auth.countryCode,@"email":auth.email,@"password":auth.password,@"deviceUID":auth.deviceUID};
    } else {
        authorizationData = @{@"email":auth.email,@"password":auth.password,@"deviceUID":auth.deviceUID};
    }
    
    // replace path to test users plist
    NSString *projectDirectoryPath = WRAPLIVE_PROJECT_DIR;
    NSString *currentTestUsersPath = [projectDirectoryPath stringByAppendingPathComponent:@"WrapLive/Resources/Property Lists/Test Users/WLTestUsers.plist"];
    
    NSMutableDictionary *testUsers = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:currentTestUsersPath]];
    
    NSMutableArray *environmentTestUsers = [NSMutableArray arrayWithArray:[testUsers objectForKey:[WLAPIEnvironment currentEnvironment].name]];
    
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
    
    testUsers[[WLAPIEnvironment currentEnvironment].name] = environmentTestUsers;
    
    [testUsers writeToFile:currentTestUsersPath atomically:YES];
#endif
}

+ (void)preloadFirstWrapsWithUser:(WLUser*)user {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        runUnaryQueuedOperation(WLOperationFetchingDataQueue,^(WLOperation *operation) {
            [[WLPaginatedRequest wraps:nil] fresh:^(NSSet *set) {
                NSOrderedSet *wraps = [user sortedWraps];
                if (wraps.count > 0) {
                    [wraps enumerateObjectsUsingBlock:^(WLWrap *wrap, NSUInteger idx, BOOL *stop) {
                        [wrap preload];
                        if (idx == 2) *stop = YES;
                    }];
                }
                [operation finish];
            } failure:^(NSError *error) {
                [operation finish];
            }];
        });
    });
}

+ (instancetype)whois:(NSString *)email {
    return [[[self GET:@"users/whois"] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:email forKey:@"email"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        WLWhoIs* whoIs = [WLWhoIs sharedInstance];
        NSDictionary *userInfo = [response.data dictionaryForKey:WLUserKey];
        whoIs.found = [userInfo boolForKey:@"found"];
        whoIs.confirmed = [userInfo boolForKey:@"confirmed_email"];
        NSString* userUID = [WLUser API_identifier:userInfo];
        if (userUID.nonempty) {
            [[WLUser entry:userUID] setCurrent];
        }
        WLAuthorization* authorization = [[WLAuthorization alloc] init];
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
    return [[[self POST:@"users/link_device"] parametrize:^(WLAPIRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[WLAuthorization currentAuthorization].email forKey:WLEmailKey];
        [parameters trySetObject:[WLAuthorization currentAuthorization].deviceUID forKey:@"device_uid"];
        [parameters trySetObject:passcode forKey:@"approval_code"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        WLAuthorization *authorization = [WLAuthorization currentAuthorization];
        authorization.password = [[response.data dictionaryForKey:@"device"] stringForKey:@"password"];
        [authorization setCurrent];
        success(authorization);
    }];
}

- (BOOL)skipReauthorizing {
    return YES;
}

@end

@implementation WLAuthorization (WLAuthorizationRequest)

- (id)signUp:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure {
    return [[WLAuthorizationRequest signUp:self] send:success failure:failure];
}

- (id)activate:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure {
    return [[WLAuthorizationRequest activation:self] send:success failure:failure];
}

- (id)signIn:(WLUserBlock)success failure:(WLFailureBlock)failure {
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

