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
@class WLWrap;
@class WLCandy;
@class WLComment;
@class WLAPIResponse;
@class WLWrapDate;

typedef void (^WLAPIManagerSuccessBlock) (id object);
typedef void (^WLAPIManagerFailureBlock) (NSError* error);
typedef id (^WLAPIManagerObjectBlock)(WLAPIResponse* response);

static NSInteger WLAPIGeneralPageSize = 10;
static NSInteger WLAPIChatPageSize = 50;

@interface WLAPIManager : AFHTTPRequestOperationManager

+ (instancetype)instance;

/*!
 *  Register an user account in WrapLive. Account cannot be used until activation is completed.
 *
 *  @param user    WLUser instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)signUp:(WLUser*)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Activate a registered account with the activation code received from SMS.
 *
 *  @param user    WLUser instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)activate:(WLUser*)user code:(NSString*)code success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Login to WrapLive.
 *
 *  @param user    WLUser instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)signIn:(WLUser*)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Get current authenticated user information. Data is available only after a successful login.
 *
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)me:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Update the user attributes of the currently logged on user. The following attributes are supported:
 1. Avatar photo
 *
 *  @param user    WLUser instance with profile information
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)updateMe:(WLUser*)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Given an array of phone numbers, return the sign up status as well as the full phone number found.
 *
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)contributors:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Get current authenticated user wraps.
 *
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)wraps:(NSInteger)page success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Get detailed wrap data. page = 1
 *
 *  @wrap wrap object
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)wrap:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Get detailed wrap data
 *
 *  @wrap wrap object
 *  @page page for dates
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)wrap:(WLWrap*)wrap page:(NSInteger)page success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Creates new wrap
 *
 *  @wrap wrap object
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)createWrap:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Update selected wrap
 *
 *  @wrap wrap object
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)updateWrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Remove wrap
 *
 *  @wrap wrap object
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)removeWrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Adds a candy to the wrap
 *
 *  @param candy    WLCandy instance representing candy
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)addCandy:(WLCandy*)candy wrap:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Get candies from the wrap
 *
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)candies:(WLWrap*)wrap date:(WLWrapDate*)date success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  (Login required) Return the chat messages in a wrap given a wrap UID. Messages are sorted in descending order. Pagination is also supported
 *
 *  @param wrap    WLWrap instance representing wrap
 *  @param page    page number
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)messages:(WLWrap*)wrap page:(NSUInteger)page success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Get all the data about a particular candy
 *
 *  @param candy   WLCandy instance representing candy
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)candy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Remove candy
 *
 *  @param candy   WLCandy instance representing candy
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)removeCandy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Add a comment to a candy in a wrap given the wrap and candy uid
 *
 *  @param comment    WLComment instance representing comment
 *  @param candy    WLCandy instance representing candy
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)addComment:(WLComment*)comment candy:(WLCandy*)candy wrap:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

/*!
 *  Remove comment
 *
 *  @param comment    WLComment instance representing comment
 *  @param candy    WLCandy instance representing candy
 *  @param wrap    WLWrap instance representing wrap
 *  @param success block that will be invoked on success completion
 *  @param failure block that will be invoked on failure completion
 */
- (id)removeComment:(WLComment*)comment candy:(WLCandy*)candy wrap:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

@end
