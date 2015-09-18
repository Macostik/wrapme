//
//  WLAPIManager.h
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSError+WLAPIManager.h"
#import "WLEntryManager.h"
#import "WLAuthorization.h"
#import "WLAPIEnvironment.h"

@class WLUser;
@class WLComment;
@class WLAPIResponse;
@class WLDate;
@class WLAuthorization;
@class WLAPIRequest;

@interface WLEntry (WLAPIManager)

@property (readonly, nonatomic) BOOL fetched;

@property (readonly, nonatomic) BOOL recursivelyFetched;

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)update:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)fetchIfNeeded:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)recursivelyFetchIfNeeded:(WLBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLWrap (WLAPIManager)

- (id)fetch:(NSString*)contentType success:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (id)messagesNewer:(NSDate*)newer success:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (id)messagesOlder:(NSDate*)older newer:(NSDate*)newer success:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (id)messages:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (void)preload;

@end

@interface WLCandy (WLAPIManager)

@end

@interface WLMessage (WLAPIManager)

@end

@interface WLComment (WLAPIManager)

@end
