//
//  WLAPIManager.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "NSError+WLAPIManager.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "WLAuthorization.h"
#import "WLBlocks.h"

@class WLUser;
@class WLComment;
@class WLAPIResponse;
@class WLWrapDate;
@class WLAuthorization;

static NSInteger WLAPIGeneralPageSize = 10;
static NSInteger WLAPIChatPageSize = 50;

@interface WLAPIManager : AFHTTPRequestOperationManager

+ (instancetype)instance;

+ (BOOL)developmentEvironment;

/*!
 *  Register an user account in WrapLive. Account cannot be used until activation is completed.
 *
 *  @param user    WLAuthorization instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)signUp:(WLAuthorization*)authorization success:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Activate a registered account with the activation code received from SMS.
 *
 *  @param user    WLAuthorization instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)activate:(WLAuthorization*)authorization success:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Login to WrapLive.
 *
 *  @param user    WLUser instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)signIn:(WLAuthorization*)authorization success:(WLUserBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Get current authenticated user information. Data is available only after a successful login.
 *
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)me:(WLUserBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Update the user attributes of the currently logged on user. The following attributes are supported:
 1. Avatar photo
 *
 *  @param user    WLUser instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)updateMe:(WLUser*)user success:(WLUserBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Given an array of phone numbers, return the sign up status as well as the full phone number found.
 *
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)contributors:(WLArrayBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Get current authenticated user wraps.
 *
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)wraps:(NSInteger)page success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Get detailed wrap data. page = 1
 *
 *  @wrap wrap object
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)wrap:(WLWrap*)wrap success:(WLWrapBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Get detailed wrap data
 *
 *  @wrap wrap object
 *  @page page for dates
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)wrap:(WLWrap*)wrap page:(NSInteger)page success:(WLWrapBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Creates new wrap
 *
 *  @wrap wrap object
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)createWrap:(WLWrap*)wrap success:(WLWrapBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Update selected wrap
 *
 *  @wrap wrap object
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)updateWrap:(WLWrap *)wrap success:(WLWrapBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Leave wrap
 *
 *  @wrap wrap object
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)leaveWrap:(WLWrap *)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Remove wrap
 *
 *  @wrap wrap object
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)removeWrap:(WLWrap *)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Adds a candy to the wrap
 *
 *  @param candy    WLCandy instance representing candy
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)addCandy:(WLCandy*)candy wrap:(WLWrap*)wrap success:(WLCandyBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Get candies from the wrap
 *
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)candies:(WLWrap*)wrap date:(WLWrapDate*)date success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

/*!
 *  (Login required) Return the chat messages in a wrap given a wrap UID. Messages are sorted in descending order. Pagination is also supported
 *
 *  @param wrap    WLWrap instance representing wrap
 *  @param page    page number
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)messages:(WLWrap*)wrap page:(NSUInteger)page success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Get all the data about a particular candy
 *
 *  @param candy   WLCandy instance representing candy
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)candy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLCandyBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Remove candy
 *
 *  @param candy   WLCandy instance representing candy
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)removeCandy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Add a comment to a candy in a wrap given the wrap and candy uid
 *
 *  @param comment    WLComment instance representing comment
 *  @param candy    WLCandy instance representing candy
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)addComment:(WLComment*)comment candy:(WLCandy*)candy wrap:(WLWrap*)wrap success:(WLCommentBlock)success failure:(WLFailureBlock)failure;

/*!
 *  Remove comment
 *
 *  @param comment    WLComment instance representing comment
 *  @param candy    WLCandy instance representing candy
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)removeComment:(WLComment*)comment candy:(WLCandy*)candy wrap:(WLWrap*)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLWrap (WLAPIManager)

- (id)create:(WLWrapBlock)success failure:(WLFailureBlock)failure;

- (id)update:(WLWrapBlock)success failure:(WLFailureBlock)failure;

- (id)fetch:(WLWrapBlock)success failure:(WLFailureBlock)failure;

- (id)fetch:(NSInteger)page success:(WLWrapBlock)success failure:(WLFailureBlock)failure;

- (id)addCandy:(WLCandy*)candy success:(WLCandyBlock)success failure:(WLFailureBlock)failure;

- (id)candies:(WLWrapDate*)date success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (id)messages:(NSUInteger)page success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)leave:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)removeCandy:(WLCandy *)candy success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLCandy (WLAPIManager)

- (id)addComment:(WLComment*)comment wrap:(WLWrap*)wrap success:(WLCommentBlock)success failure:(WLFailureBlock)failure;

- (id)removeComment:(WLComment*)comment wrap:(WLWrap*)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)remove:(WLWrap*)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)fetch:(WLWrap *)wrap success:(WLCandyBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLAuthorization (WLAPIManager)

- (id)signUp:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure;

- (id)activate:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure;

- (id)signIn:(WLUserBlock)success failure:(WLFailureBlock)failure;

@end
