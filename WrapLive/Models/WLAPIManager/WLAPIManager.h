//
//  WLAPIManager.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "NSError+WLAPIManager.h"

@class WLUser;

typedef void (^WLAPIManagerSuccessBlock) (id object);
typedef void (^WLAPIManagerFailureBlock) (NSError* error);

@interface WLAPIManager : AFHTTPRequestOperationManager

+ (instancetype)instance;

/*!
 *  Register an user account in WrapLive. Account cannot be used until activation is completed.
 *
 *  @param user    WLUser instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (void)signUp:(WLUser*)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Activate a registered account with the activation code received from SMS.
 *
 *  @param user    WLUser instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (void)activate:(WLUser*)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Login to WrapLive.
 *
 *  @param user    WLUser instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (void)signIn:(WLUser*)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Get current authenticated user information. Data is available only after a successful login.
 *
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (void)me:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Update the user attributes of the currently logged on user. The following attributes are supported:
 1. Avatar photo
 *
 *  @param user    WLUser instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (void)updateMe:(WLUser*)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Get current authenticated user wraps.
 *
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (void)wraps:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

@end
