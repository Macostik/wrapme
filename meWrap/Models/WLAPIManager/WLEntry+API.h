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

+ (instancetype)entry;

+ (instancetype)entry:(NSString *)identifier container:(WLEntry*)container;

+ (instancetype)entry:(NSString *)identifier uploadIdentifier:(NSString *)uploadIdentifier;

+ (NSSet*)API_entries:(NSArray*)array;

+ (instancetype)API_entry:(NSDictionary*)dictionary;

+ (NSSet*)API_entries:(NSArray*)array container:(id)container;

+ (instancetype)API_entry:(NSDictionary*)dictionary container:(id)container;

+ (NSString*)API_identifier:(NSDictionary*)dictionary;

+ (NSString *)API_uploadIdentifier:(NSDictionary *)dictionary;

- (instancetype)API_setup:(NSDictionary*)dictionary;

- (instancetype)API_setup:(NSDictionary*)dictionary container:(id)container;

+ (NSArray*)API_prefetchArray:(NSArray*)array;

+ (NSDictionary*)API_prefetchDictionary:(NSDictionary*)dictionary;

+ (void)API_prefetchDescriptors:(NSMutableDictionary*)descriptors inArray:(NSArray*)array;

+ (void)API_prefetchDescriptors:(NSMutableDictionary*)descriptors inDictionary:(NSDictionary*)dictionary;

- (instancetype)update:(NSDictionary *)dictionary;

- (void)touch;

- (void)touch:(NSDate*)date;

- (void)editPicture:(WLAsset*)editedPicture;

- (void)markAsRead;

- (void)markAsUnread;

@end

@interface WLUser (WLAPIManager) @end

@interface WLDevice (WLAPIManager) @end

@interface WLContribution (WLAPIManager)

+ (instancetype)contribution;

+ (NSNumber*)uploadingOrder;

@end

@interface WLWrap (WLAPIManager)

+ (instancetype)wrap;

- (id)fetch:(NSString*)contentType success:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (id)messagesNewer:(NSDate*)newer success:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (id)messagesOlder:(NSDate*)older newer:(NSDate*)newer success:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (id)messages:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (void)preload;

@end

@interface WLCandy (WLAPIManager)

+ (instancetype)candyWithType:(NSInteger)type wrap:(WLWrap*)wrap;

- (void)addComment:(WLComment *)comment;

- (void)removeComment:(WLComment *)comment;

- (void)setEditedPictureIfNeeded:(WLAsset *)editedPicture;

@end

@interface WLMessage (WLAPIManager)

@end

@interface WLComment (WLAPIManager)

+ (instancetype)comment:(NSString*)text;

@end
