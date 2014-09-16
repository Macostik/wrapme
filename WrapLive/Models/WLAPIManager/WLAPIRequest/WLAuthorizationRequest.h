//
//  WLAuthorizationRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

typedef NS_ENUM(NSUInteger, WLAuthorizationStep) {
    WLAuthorizationStepSignUp,
    WLAuthorizationStepActivation,
    WLAuthorizationStepSignIn
};

@interface WLAuthorizationRequest : WLAPIRequest

@property (strong, nonatomic) WLAuthorization* authorization;

@property (nonatomic) WLAuthorizationStep step;

@property (nonatomic) BOOL tryUncorfirmedEmail;

+ (BOOL)authorized;

+ (instancetype)request:(WLAuthorizationStep)step authorization:(WLAuthorization*)authorization;

+ (instancetype)request:(WLAuthorizationStep)step;

+ (instancetype)signUpRequest:(WLAuthorization*)authorization;

+ (instancetype)activationRequest:(WLAuthorization*)authorization;

+ (instancetype)signInRequest:(WLAuthorization*)authorization;

+ (instancetype)signUpRequest;

+ (instancetype)activationRequest;

+ (instancetype)signInRequest;

@end

@interface WLAuthorization (WLAuthorizationRequest)

- (id)signUp:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure;

- (id)activate:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure;

- (id)signIn:(WLUserBlock)success failure:(WLFailureBlock)failure;

@end
