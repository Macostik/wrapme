//
//  WLAuthorizationRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAuthorizationRequest.h"
#import "WLWelcomeViewController.h"
#import "WLNavigation.h"

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
            [WLUploading enqueueAutomaticUploading:^{ }];
        }
        id pageSize = [response.data objectForKey:@"pagination_fetch_size"];
        if (pageSize) {
            WLPageSize = [pageSize integerValue];
        }
        
        NSDictionary* userData = [response.data dictionaryForKey:@"user"];
        
		WLUser* user = [WLUser API_entry:userData];
        [self.authorization updateWithUserData:userData];
		[user setCurrent];
		return user;
    }
    return self.authorization;
}

- (void)handleFailure:(NSError *)error {
    if([error isError:WLErrorNotFoundEntry] && !self.tryUncorfirmedEmail && self.authorization.unconfirmed_email.nonempty)  {
        self.tryUncorfirmedEmail = YES;
        [self send];
    } else {
        [super handleFailure:error];
    }
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
    WLWhoIs* whoIs = [[WLWhoIs alloc] init];
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
    NSArray* deviceUIDs = [userInfo arrayForKey:@"device_uids"];
    whoIs.requiresVerification = !deviceUIDs.nonempty || [deviceUIDs containsObject:authorization.deviceUID];
    return whoIs;
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

@end

