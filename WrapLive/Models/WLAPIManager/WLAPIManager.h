//
//  WLAPIManager.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "NSError+WLAPIManager.h"
#import "WLEntryManager.h"
#import "WLAuthorization.h"
#import "WLBlocks.h"

@class WLUser;
@class WLComment;
@class WLAPIResponse;
@class WLDate;
@class WLAuthorization;

@interface WLAPIManager : AFHTTPRequestOperationManager

+ (instancetype)instance;

+ (BOOL)developmentEvironment;

- (NSString*)urlWithPath:(NSString*)path;

@end

@interface WLEntry (WLAPIManager)

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)update:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLWrap (WLAPIManager)

- (id)fetch:(NSInteger)page success:(WLWrapBlock)success failure:(WLFailureBlock)failure;

- (id)messagesNewer:(NSDate*)newer success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)messagesOlder:(NSDate*)older success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)messages:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)latestMessage:(WLCandyBlock)success failure:(WLFailureBlock)failure;

- (id)leave:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLCandy (WLAPIManager)

@end

@interface WLComment (WLAPIManager)

@end
