//
//  WLAuthorizationRequest.h
//  meWrap
//
//  Created by Ravenpod on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLAuthorizationRequest : WLAPIRequest

@property (nonatomic) BOOL tryUncorfirmedEmail;

+ (BOOL)authorized;

+ (BOOL)requiresSignIn;

+ (instancetype)signUp:(Authorization*)authorization;

+ (instancetype)activation:(Authorization*)authorization;

+ (instancetype)signIn:(Authorization*)authorization;

+ (instancetype)signUp;

+ (instancetype)activation;

+ (instancetype)signIn;

+ (instancetype)whois:(NSString*)email;

+ (instancetype)linkDevice:(NSString*)passcode;

+ (instancetype)updateDevice;

@end

@interface Authorization (WLAuthorizationRequest)

- (id)signUp:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)activate:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)signIn:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLWhoIs : NSObject

@property (nonatomic) BOOL found;

@property (nonatomic) BOOL confirmed;

@property (nonatomic) BOOL requiresApproving;

@property (nonatomic) BOOL containsPhoneDevice;

+ (instancetype)sharedInstance;

@end
