//
//  WLAuthorizationRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAuthorizationRequest.h"
#import "WLWelcomeViewController.h"
#import "WLUploadingQueue.h"
#import "WLWrapsRequest.h"
#import "WLOperationQueue.h"

@implementation WLAuthorizationRequest

static BOOL authorized = NO;

+ (BOOL)authorized {
    return authorized;
}

+ (NSString *)defaultMethod {
    return @"POST";
}

+ (instancetype)request:(WLAuthorizationStep)step authorization:(WLAuthorization *)authorization {
    WLAuthorizationRequest* request = [WLAuthorizationRequest request];
    request.step = step;
    request.authorization = authorization;
    return request;
}

+ (instancetype)request:(WLAuthorizationStep)step {
    return [self request:step authorization:[WLAuthorization currentAuthorization]];
}

+ (instancetype)signUpRequest:(WLAuthorization*)authorization {
    return [self request:WLAuthorizationStepSignUp authorization:authorization];
}

+ (instancetype)activationRequest:(WLAuthorization*)authorization {
    return [self request:WLAuthorizationStepActivation authorization:authorization];
}

+ (instancetype)signInRequest:(WLAuthorization*)authorization {
    return [self request:WLAuthorizationStepSignIn authorization:authorization];
}

+ (instancetype)signUpRequest {
    return [self signUpRequest:[WLAuthorization currentAuthorization]];
}

+ (instancetype)activationRequest {
    return [self activationRequest:[WLAuthorization currentAuthorization]];
}

+ (instancetype)signInRequest {
    return [self signInRequest:[WLAuthorization currentAuthorization]];
}

- (NSString *)path {
    if (self.step == WLAuthorizationStepSignUp) {
        return @"users";
    } else if (self.step == WLAuthorizationStepActivation) {
        return @"users/activate";
    } else if (self.step == WLAuthorizationStepSignIn) {
        return @"users/sign_in";
    }
    return nil;
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    WLAuthorization* authorization = self.authorization;
    if (!authorization) {
        authorization = [WLAuthorization currentAuthorization];
        self.authorization = authorization;
    }
    [parameters trySetObject:authorization.deviceUID forKey:@"device_uid"];
    [parameters trySetObject:authorization.deviceName forKey:@"device_name"];
    [parameters trySetObject:authorization.countryCode forKey:@"country_calling_code"];
	[parameters trySetObject:authorization.phone forKey:@"phone_number"];
	[parameters trySetObject:authorization.password forKey:@"password"];
    [parameters trySetObject:authorization.activationCode forKey:@"activation_code"];
    [parameters trySetObject:self.tryUncorfirmedEmail ? authorization.unconfirmed_email : authorization.email forKey:@"email"];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    if (self.step == WLAuthorizationStepActivation) {
        self.authorization.password = [[response.data dictionaryForKey:@"device"] stringForKey:@"password"];
		[self.authorization setCurrent];
    } else if (self.step == WLAuthorizationStepSignIn) {
        if (!authorized) {
            authorized = YES;
            [WLUploadingQueue start];
        }
        id pageSize = [response.data objectForKey:@"pagination_fetch_size"];
        if (pageSize) {
            WLPageSize = [pageSize integerValue];
        }
        
        NSDictionary* userData = [response.data dictionaryForKey:@"user"];
        
		WLUser* user = [WLUser API_entry:userData];
        [self.authorization updateWithUserData:userData];
		[user setCurrent];
        
        if (user.firstTimeUse) {
            [self preloadFirstWrapsWithUser:user];
        }

        // code for easily saving test user data
#if TARGET_IPHONE_SIMULATOR
        [self saveTestUserData];
#endif
        
		return user;
    }
    return self.authorization;
}

- (void)saveTestUserData {
    NSDictionary *authorizationData = nil;
    if (self.authorization.phone.nonempty && self.authorization.countryCode.nonempty) {
        authorizationData = @{@"phone":self.authorization.phone,@"countryCode":self.authorization.countryCode,@"email":self.authorization.email,@"password":self.authorization.password,@"deviceUID":self.authorization.deviceUID};
    } else {
        authorizationData = @{@"email":self.authorization.email,@"password":self.authorization.password,@"deviceUID":self.authorization.deviceUID};
    }
    
    // replace path to test users plist
    NSString *currentTestUsersPath = @"/Users/sergeymaximenko/projects/wraplive-ios/WrapLive/Resources/Property Lists/Test Users/WLTestUsers.plist";
    
    NSMutableDictionary *testUsers = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:currentTestUsersPath]];
    
    NSMutableArray *environmentTestUsers = [NSMutableArray arrayWithArray:[testUsers objectForKey:[WLAPIManager manager].environment.name]];
    for (NSDictionary *testUser in environmentTestUsers) {
        if ([testUser[@"email"] isEqualToString:authorizationData[@"email"]] && [testUser[@"deviceUID"] isEqualToString:authorizationData[@"deviceUID"]]) {
            return;
        }
    }
    
    [environmentTestUsers addObject:authorizationData];
    
    testUsers[[WLAPIManager manager].environment.name] = environmentTestUsers;
    
    [testUsers writeToFile:currentTestUsersPath atomically:YES];
}

- (void)preloadFirstWrapsWithUser:(WLUser*)user {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        runUnaryQueuedOperation(WLOperationFetchingDataQueue,^(WLOperation *operation) {
            [[WLWrapsRequest request] fresh:^(NSOrderedSet *orderedSet) {
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

- (void)handleFailure:(NSError *)error {
    if([error isError:WLErrorNotFoundEntry] && !self.tryUncorfirmedEmail && self.authorization.unconfirmed_email.nonempty)  {
        self.tryUncorfirmedEmail = YES;
        [self send];
    } else {
        [super handleFailure:error];
    }
}

- (BOOL)reauthorizationEnabled {
    return NO;
}

@end

@implementation WLWhoIsRequest

- (NSString *)path {
    return @"users/whois";
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    [parameters trySetObject:self.email forKey:@"email"];
    return [super configure:parameters];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLWhoIs* whoIs = [WLWhoIs sharedInstance];
    NSDictionary *userInfo = [response.data dictionaryForKey:WLUserKey];
    whoIs.found = [userInfo boolForKey:@"found"];
    whoIs.confirmed = [userInfo boolForKey:@"confirmed_email"];
    NSString* userUID = [WLUser API_identifier:userInfo];
    if (userUID.nonempty) {
        [[WLUser entry:userUID] setCurrent];
    }
    WLAuthorization* authorization = [[WLAuthorization alloc] init];
    authorization.email = self.email;
    if (!whoIs.confirmed) {
        authorization.unconfirmed_email = self.email;
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
    
    return whoIs;
}

- (BOOL)reauthorizationEnabled {
    return NO;
}

@end

@implementation WLLinkDeviceRequest

+ (NSString *)defaultMethod {
    return @"POST";
}

- (NSString *)path {
    return @"users/link_device";
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    [parameters trySetObject:self.email forKey:WLEmailKey];
    [parameters trySetObject:self.deviceUID forKey:@"device_uid"];
    [parameters trySetObject:self.approvalCode forKey:@"approval_code"];
    return [super configure:parameters];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLAuthorization *authorization = [WLAuthorization currentAuthorization];
    authorization.password = [[response.data dictionaryForKey:@"device"] stringForKey:@"password"];
    [authorization setCurrent];
    return authorization;
}

- (BOOL)reauthorizationEnabled {
    return NO;
}

@end

@implementation WLAuthorization (WLAuthorizationRequest)

- (id)signUp:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure {
    return [[WLAuthorizationRequest signUpRequest:self] send:success failure:failure];
}

- (id)activate:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure {
    return [[WLAuthorizationRequest activationRequest:self] send:success failure:failure];
}

- (id)signIn:(WLUserBlock)success failure:(WLFailureBlock)failure {
	return [[WLAuthorizationRequest signInRequest:self] send:success failure:failure];
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

