//
//  WLAPIManager.h
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

@class WLAPIRequest;

@interface Entry (WLAPIManager)

- (id)fetch:(ObjectBlock)success failure:(FailureBlock)failure;

- (id)fetchIfNeeded:(ObjectBlock)success failure:(FailureBlock)failure;

- (void)recursivelyFetchIfNeeded:(Block)success failure:(FailureBlock)failure;

+ (NSArray*)prefetchArray:(NSArray*)array;

+ (NSDictionary*)prefetchDictionary:(NSDictionary*)dictionary;

+ (void)prefetchDescriptors:(NSMutableDictionary*)descriptors inArray:(NSArray*)array;

+ (void)prefetchDescriptors:(NSMutableDictionary*)descriptors inDictionary:(NSDictionary*)dictionary;

- (instancetype)update:(NSDictionary *)dictionary;

@end

@interface Contribution (WLAPIManager)

@end

@interface Wrap (WLAPIManager)

- (id)fetch:(NSString*)contentType success:(ArrayBlock)success failure:(FailureBlock)failure;

- (id)messagesNewer:(NSDate*)newer success:(ArrayBlock)success failure:(FailureBlock)failure;

- (id)messagesOlder:(NSDate*)older newer:(NSDate*)newer success:(ArrayBlock)success failure:(FailureBlock)failure;

- (id)messages:(ArrayBlock)success failure:(FailureBlock)failure;

- (void)preload;

@end

@interface Candy (WLAPIManager)

- (void)download:(Block)success failure:(FailureBlock)failure;

@end
