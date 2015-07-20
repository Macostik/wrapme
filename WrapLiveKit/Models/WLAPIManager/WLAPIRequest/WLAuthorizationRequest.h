//
//  WLAuthorizationRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

@interface WLAuthorizationRequest : WLAPIRequest

@property (nonatomic) BOOL tryUncorfirmedEmail;

+ (BOOL)authorized;

+ (instancetype)signUp:(WLAuthorization*)authorization;

+ (instancetype)activation:(WLAuthorization*)authorization;

+ (instancetype)signIn:(WLAuthorization*)authorization;

+ (instancetype)signUp;

+ (instancetype)activation;

+ (instancetype)signIn;

@end

@interface WLAPIRequest (WLWhoIs)

+ (instancetype)whois:(NSString*)email;

@end

@interface WLLinkDeviceRequest : WLAPIRequest

@property (strong, nonatomic) NSString *email;

@property (strong, nonatomic) NSString *deviceUID;

@property (strong, nonatomic) NSString *approvalCode;

@end

@interface WLAuthorization (WLAuthorizationRequest)

- (id)signUp:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure;

- (id)activate:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure;

- (id)signIn:(WLUserBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLWhoIs : NSObject

@property (nonatomic) BOOL found;

@property (nonatomic) BOOL confirmed;

@property (nonatomic) BOOL requiresApproving;

@property (nonatomic) BOOL containsPhoneDevice;

+ (instancetype)sharedInstance;

@end
