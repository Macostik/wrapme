//
//  WLAPIManager.h
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSError+WLAPIManager.h"
#import "WLAPIEnvironment.h"

@class WLAPIResponse;
@class WLAPIRequest;

@interface Entry (WLAPIManager)

@property (readonly, nonatomic) BOOL fetched;

@property (readonly, nonatomic) BOOL recursivelyFetched;

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)update:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)fetchIfNeeded:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)recursivelyFetchIfNeeded:(WLBlock)success failure:(WLFailureBlock)failure;

+ (NSArray*)API_prefetchArray:(NSArray*)array;

+ (NSDictionary*)API_prefetchDictionary:(NSDictionary*)dictionary;

+ (void)API_prefetchDescriptors:(NSMutableDictionary*)descriptors inArray:(NSArray*)array;

+ (void)API_prefetchDescriptors:(NSMutableDictionary*)descriptors inDictionary:(NSDictionary*)dictionary;

- (instancetype)update:(NSDictionary *)dictionary;

- (void)touch;

- (void)touch:(NSDate*)date;

@end

@interface User (WLAPIManager) @end

@interface Device (WLAPIManager) @end

@interface Contribution (WLAPIManager)

+ (NSNumber*)uploadingOrder;

@end

@interface Wrap (WLAPIManager)

- (id)fetch:(NSString*)contentType success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (id)messagesNewer:(NSDate*)newer success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (id)messagesOlder:(NSDate*)older newer:(NSDate*)newer success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (id)messages:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (void)preload;

@end

@interface Candy (WLAPIManager)

- (void)setEditedPictureIfNeeded:(Asset *)editedPicture;

- (void)download:(WLBlock)success failure:(WLFailureBlock)failure;

@end

@interface Message (WLAPIManager)

@end

@interface Comment (WLAPIManager)

+ (instancetype)comment:(NSString*)text;

@end

@interface NSString (Unicode)

- (NSString *)escapedUnicode;

@end
