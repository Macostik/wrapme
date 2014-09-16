//
//  WLAuthorizationRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAuthorizationRequest.h"

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
        self.authorization.password = [response.data stringForKey:@"password"];
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
		WLUser* user = [WLUser API_entry:[response.data dictionaryForKey:@"user"]];
		[user setCurrent];
		[self.authorization setCurrent];
		return user;
    }
    return self.authorization;
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
