//
//  WLAPIManager.h
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

@class WLAPIRequest;

@interface Entry (WLAPIManager)

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)update:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)fetchIfNeeded:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)recursivelyFetchIfNeeded:(WLBlock)success failure:(WLFailureBlock)failure;

+ (NSArray*)prefetchArray:(NSArray*)array;

+ (NSDictionary*)prefetchDictionary:(NSDictionary*)dictionary;

+ (void)prefetchDescriptors:(NSMutableDictionary*)descriptors inArray:(NSArray*)array;

+ (void)prefetchDescriptors:(NSMutableDictionary*)descriptors inDictionary:(NSDictionary*)dictionary;

- (instancetype)update:(NSDictionary *)dictionary;

@end

@interface User (WLAPIManager) @end

@interface Device (WLAPIManager) @end

@interface Contribution (WLAPIManager)

@end

@interface Wrap (WLAPIManager)

- (id)fetch:(NSString*)contentType success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (id)messagesNewer:(NSDate*)newer success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (id)messagesOlder:(NSDate*)older newer:(NSDate*)newer success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (id)messages:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (void)preload;

@end

@interface Candy (WLAPIManager)

- (void)download:(WLBlock)success failure:(WLFailureBlock)failure;

@end

@interface Message (WLAPIManager)

@end

@interface Comment (WLAPIManager)

@end

@interface NSString (Unicode)

- (NSString *)escapedUnicode;

@end
