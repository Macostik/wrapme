//
//  WLAPIManager.m
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntry+API.h"
#import "WLSession.h"
#import "NSDate+Formatting.h"
#import "WLCollections.h"
#import "WLAddressBook.h"
#import "WLEntryNotifier.h"
#import "NSString+Additions.h"
#import "WLAuthorization.h"
#import "NSDate+Additions.h"
#import "WLWelcomeViewController.h"
#import "WLImageCache.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAuthorizationRequest.h"
#import "WLOperationQueue.h"
#import "WLHistory.h"
#import "WLAlertView.h"
#import <AWSS3/AWSS3.h>
#import "WLEntryDescriptor.h"

@implementation WLEntry (WLAPIManager)

+ (instancetype)entry {
    WLEntry* entry = [self entry:GUID()];
    entry.createdAt = [NSDate now];
    entry.updatedAt = entry.createdAt;
    return entry;
}

+ (instancetype)entry:(NSString *)identifier container:(WLEntry*)container {
    WLEntry* entry = [self entry:identifier];
    entry.container = container;
    return entry;
}

+ (NSSet*)API_entries:(NSArray*)array {
    return [self API_entries:array container:nil];
}

+ (NSSet*)API_entries:(NSArray*)array container:(id)container {
    if (array.count == 0) {
        return nil;
    }
    NSMutableSet *set = [NSMutableSet setWithCapacity:[array count]];
    for (NSDictionary* dictionary in array) {
        WLEntry* entry = [self API_entry:dictionary container:container];
        if (entry) {
            [set addObject:entry];
        }
    }
    return set;
}

+ (instancetype)API_entry:(NSDictionary*)dictionary {
    return [self API_entry:dictionary container:nil];
}

+ (instancetype)API_entry:(NSDictionary *)dictionary container:(id)container {
    NSString* identifier = [self API_identifier:dictionary];
    return [[self entry:identifier] API_setup:dictionary container:container];
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
    return nil;
}

+ (NSString *)API_uploadIdentifier:(NSDictionary *)dictionary {
    return nil;
}

+ (NSArray*)API_prefetchArray:(NSArray *)array {
    NSMutableDictionary *descriptors = [NSMutableDictionary dictionary];
    [self API_prefetchDescriptors:descriptors inArray:array];
    [[WLEntryManager manager] fetchEntries:descriptors];
    return array;
}

+ (NSDictionary*)API_prefetchDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *descriptors = [NSMutableDictionary dictionary];
    [self API_prefetchDescriptors:descriptors inDictionary:dictionary];
    [[WLEntryManager manager] fetchEntries:descriptors];
    return dictionary;
}

+ (void)API_prefetchDescriptors:(NSMutableDictionary*)descriptors inArray:(NSArray*)array {
    for (NSDictionary *dictionary in array) {
        [self API_prefetchDescriptors:descriptors inDictionary:dictionary];
    }
}

+ (void)API_prefetchDescriptors:(NSMutableDictionary*)descriptors inDictionary:(NSDictionary*)dictionary {
    NSString *identifier = [self API_identifier:dictionary];
    if (identifier && [descriptors objectForKeyedSubscript:identifier] == nil) {
        WLEntryDescriptor *descriptor = [[WLEntryDescriptor alloc] init];
        descriptor.entryClass = self;
        descriptor.identifier = identifier;
        descriptor.uploadIdentifier = [self API_uploadIdentifier:dictionary];
        [descriptors setObject:descriptor forKey:identifier];
    }
}

- (instancetype)API_setup:(NSDictionary *)dictionary {
    if (dictionary) {
        return [self API_setup:dictionary container:nil];
    }
    return self;
}

- (instancetype)API_setup:(NSDictionary*)dictionary container:(id)container {
    NSDate* createdAt = [dictionary timestampDateForKey:WLContributedAtKey];
    if (!NSDateEqual(self.createdAt, createdAt)) self.createdAt = createdAt;
    NSDate* updatedAt = [dictionary timestampDateForKey:WLLastTouchedAtKey];
    if (updatedAt) {
        if (!self.updatedAt || [updatedAt later:self.updatedAt]) self.updatedAt = updatedAt;
    } else {
        if (!NSDateEqual(self.updatedAt, createdAt)) self.updatedAt = createdAt;
    }
    NSString* identifier = [[self class] API_identifier:dictionary];
    if (!NSStringEqual(self.identifier, identifier)) self.identifier = identifier;
    return self;
}

- (instancetype)update:(NSDictionary *)dictionary {
    [self API_setup:dictionary];
    if (self.updated) {
        [self notifyOnUpdate];
    }
    return self;
}

- (BOOL)fetched {
    return YES;
}

- (BOOL)recursivelyFetched {
    WLEntry *entry = self;
    while (entry) {
        if (!entry.fetched) {
            return NO;
        }
        entry = entry.container;
    }
    return YES;
}

- (void)recursivelyFetchIfNeeded:(WLBlock)success failure:(WLFailureBlock)failure {
    
    if (self.recursivelyFetched) {
        if (success) success();
    } else {
        __weak typeof(self)weakSelf = self;
        [self fetchIfNeeded:^ (WLEntry *entry) {
            WLEntry *container = weakSelf.container;
            if (container) {
                [container recursivelyFetchIfNeeded:success failure:failure];
            } else {
                if (success) success();
            }
        } failure:failure];
    }
}

- (id)fetchIfNeeded:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (self.fetched) {
        if (success) success(self);
        return nil;
    } else {
        __weak typeof(self)weakSelf = self;
        runQueuedOperation(@"entry_fetching", 3, ^(WLOperation *operation) {
            [weakSelf fetch:^(id object) {
                [operation finish];
                if (success) success(object);
            } failure:^(NSError *error) {
                [operation finish];
                if (failure) failure(error);
            }];
        });
        return nil;
    }
}

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    success(self);
    return nil;
}

- (id)update:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    success(self);
    return nil;
}

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (success) success(self);
    return nil;
}

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (success) success(self);
    return nil;
}

- (id)older:(BOOL)withinDay success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    success(nil);
    return nil;
}

- (id)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [self older:NO success:success failure:failure];
}

- (id)newer:(BOOL)withinDay success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    success(nil);
    return nil;
}

- (id)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [self newer:NO success:success failure:failure];
}

- (void)markAsRead {
    if (self.valid && self.unread) self.unread = NO;
}

- (void)markAsUnread {
    if (self.valid && !self.unread) self.unread = YES;
}

- (void)touch {
    [self touch:[NSDate now]];
}

- (void)touch:(NSDate *)date {
    if (self.container) {
        [self.container touch:date];
    }
    self.updatedAt = date;
    if (self.createdAt == nil) {
        self.createdAt = date;
    }
}

- (void)editPicture:(WLAsset*)editedPicture {
    if (self.picture != editedPicture) {
        self.picture = editedPicture;
    }
}

@end

@implementation WLUser (WLAPIManager)

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
    return [dictionary stringForKey:WLUserUIDKey];
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    
    if (dictionary[WLSignInCountKey]) {
        BOOL firstTimeUse = [dictionary integerForKey:WLSignInCountKey] == 1;
        if (self.firstTimeUse != firstTimeUse) self.firstTimeUse = firstTimeUse;
    }
    
    if (dictionary[WLNameKey]) {
        NSString* name = [dictionary stringForKey:WLNameKey];
        if (!NSStringEqual(self.name, name)) self.name = name;
    }
    
    [self editPicture:[self.picture edit:dictionary[WLAvatarURLsKey] metrics:[AssetMetrics avatarMetrics]]];
    
    if (dictionary[WLDevicesKey]) {
        NSSet* devices = [WLDevice API_entries:[dictionary arrayForKey:WLDevicesKey] container:self];
        if (![self.devices isEqualToSet:devices]) {
            self.devices = devices;
            self.phones = nil;
        }
    }
    
    return [super API_setup:dictionary container:container];
}

@end

@implementation WLDevice (WLAPIManager)

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
    return [dictionary stringForKey:@"device_uid"];
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    NSString* name = [dictionary stringForKey:@"device_name"];
    if (!NSStringEqual(self.name, name)) self.name = name;
    NSString* phone = [dictionary stringForKey:WLFullPhoneNumberKey];
    if (!NSStringEqual(self.phone, phone)) self.phone = phone;
    BOOL activated = [dictionary boolForKey:@"activated"];
    if (self.activated != activated) self.activated = activated;
    if (container && self.owner != container) self.owner = container;
    NSDate* invitedAt = [dictionary timestampDateForKey:@"invited_at_in_epoch"];
    if (!NSDateEqual(self.invitedAt, invitedAt)) self.invitedAt = invitedAt;
    NSString* invitedBy = [dictionary stringForKey:@"invited_by_user_uid"];
    if (!NSStringEqual(self.invitedBy, invitedBy)) self.invitedBy = invitedBy;
    return [super API_setup:dictionary container:container];
}

@end

@implementation WLContribution (WLAPIManager)

+ (instancetype)contribution {
    WLContribution* contributrion = [self entry];
    contributrion.uploadIdentifier = contributrion.identifier;
    contributrion.contributor = [WLUser currentUser];
    return contributrion;
}

+ (instancetype)entry:(NSString *)identifier uploadIdentifier:(NSString *)uploadIdentifier {
    return (id)[[WLEntryManager manager] entryOfClass:self identifier:identifier uploadIdentifier:uploadIdentifier];
}

+ (instancetype)API_entry:(NSDictionary *)dictionary container:(id)container {
    NSString *identifier = [self API_identifier:dictionary];
    NSString *uploadIdentifier = [self API_uploadIdentifier:dictionary];
    return [[self entry:identifier uploadIdentifier:uploadIdentifier] API_setup:dictionary container:container];
}

+ (NSString *)API_uploadIdentifier:(NSDictionary *)dictionary {
    return [dictionary stringForKey:WLUploadUIDKey];
}

+ (void)API_prefetchDescriptors:(NSMutableDictionary *)descriptors inDictionary:(NSDictionary *)dictionary {
    [super API_prefetchDescriptors:descriptors inDictionary:dictionary];
    
    if (dictionary[WLContributorKey]) {
        [WLUser API_prefetchDescriptors:descriptors inDictionary:dictionary[WLContributorKey]];
    }
    
    if (dictionary[WLEditorKey]) {
        [WLUser API_prefetchDescriptors:descriptors inDictionary:dictionary[WLEditorKey]];
    }
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    
    if (dictionary[WLUploadUIDKey]) {
        NSString* uploadIdentifier = [dictionary stringForKey:WLUploadUIDKey];
        if (!NSStringEqual(self.uploadIdentifier, uploadIdentifier)) self.uploadIdentifier = uploadIdentifier;
    }
    
    WLUser *contributor = [WLUser API_entry:dictionary[WLContributorKey]];
    if (self.contributor != contributor) self.contributor = contributor;
    
    WLUser *editor = [WLUser API_entry:dictionary[WLEditorKey]];
    if (self.editor != editor) self.editor = editor;
    
    NSDate* editedAt = [dictionary timestampDateForKey:WLEditedAtKey];
    if (!NSDateEqual(self.editedAt, editedAt)) self.editedAt = editedAt;
    
    return [super API_setup:dictionary container:container];
}

+ (NSNumber *)uploadingOrder {
    return @5;
}

@end

@implementation WLWrap (WLAPIManager)

+ (NSNumber *)uploadingOrder {
    return @1;
}

+ (instancetype)wrap {
    WLWrap* wrap = [self contribution];
    [wrap.contributor addWrap:wrap];
    if (wrap.contributor) {
        wrap.contributors = [NSSet setWithObject:wrap.contributor];
    }
    return wrap;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
    return [dictionary stringForKey:WLWrapUIDKey];
}

+ (void)API_prefetchDescriptors:(NSMutableDictionary *)descriptors inDictionary:(NSDictionary *)dictionary {
    [super API_prefetchDescriptors:descriptors inDictionary:dictionary];
    
    if (dictionary[WLContributorsKey]) {
        [WLUser API_prefetchDescriptors:descriptors inArray:dictionary[WLContributorsKey]];
    }
    
    if (dictionary[WLCreatorKey] != nil) {
        [WLUser API_prefetchDescriptors:descriptors inDictionary:dictionary[WLCreatorKey]];
    }
    
    if (dictionary[WLCandiesKey] != nil) {
        [WLCandy API_prefetchDescriptors:descriptors inArray:dictionary[WLCandiesKey]];
    }
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    [super API_setup:dictionary container:container];
    NSString* name = [dictionary stringForKey:WLNameKey];
    if (!NSStringEqual(self.name, name)) self.name = name;
    
    BOOL isPublic = [dictionary boolForKey:@"is_public"];
    if (self.isPublic != isPublic) self.isPublic = isPublic;
    
    BOOL isRestrictedInvite = [dictionary boolForKey:@"is_restricted_invite"];
    if (self.isRestrictedInvite != isRestrictedInvite) self.isRestrictedInvite = isRestrictedInvite;
    
    NSArray *contributorsArray = [dictionary arrayForKey:WLContributorsKey];
    if (contributorsArray.nonempty) {
        [self addContributors:[WLUser API_entries:contributorsArray]];
    }
    
    WLUser *contributor = [WLUser API_entry:dictionary[WLCreatorKey]];
    if (self.contributor != contributor) self.contributor = contributor;
    
    if (self.isPublic) {
        if (dictionary[@"is_following"]) {
            BOOL isFollowing = [dictionary boolForKey:@"is_following"];
            if (isFollowing && !self.isContributing) {
                [self addContributorsObject:[WLUser currentUser]];
            } else if (!isFollowing && self.isContributing) {
                [self removeContributorsObject:[WLUser currentUser]];
            }
        }
    } else {
        if (!self.isContributing) [self addContributorsObject:[WLUser currentUser]];
    }
    
    NSSet* candies = [WLCandy API_entries:[dictionary arrayForKey:WLCandiesKey] container:self];
    if (candies.nonempty && ![candies isSubsetOfSet:self.candies]) {
        [self addCandies:candies];
    }
    
    return self;
}

- (BOOL)fetched {
    return self.name.nonempty && self.contributor;
}

- (id)add:(WLWrapBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIRequest uploadWrap:self] send:success failure:failure];
}

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (!self.deletable) {
        return [[WLAPIRequest leaveWrap:self] send:^(id object) {
            success(object);
        } failure:failure];
    }
    id operation = nil;
    switch (self.status) {
        case WLContributionStatusReady:
            [self remove];
            if (success) success(nil);
            break;
        case WLContributionStatusInProgress:
            if (failure) failure([NSError errorWithDescription:WLLS(@"wrap_is_uploading")]);
            break;
        case WLContributionStatusFinished: {
            operation = [[WLAPIRequest deleteWrap:self] send:success failure:failure];
        }   break;
        default:
            break;
    }
    return operation;
}

- (id)fetch:(WLSetBlock)success failure:(WLFailureBlock)failure {
    return [self fetch:WLWrapContentTypeRecent success:success failure:failure];
}

- (id)fetch:(NSString*)contentType success:(WLSetBlock)success failure:(WLFailureBlock)failure {
    if (self.uploaded) {
        return [[WLPaginatedRequest wrap:self contentType:contentType] send:success failure:failure];
    } else if (success) {
        success(nil);
    }
    return nil;
}

- (id)update:(WLWrapBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIRequest updateWrap:self] send:success failure:failure];
}

- (id)messagesNewer:(NSDate *)newer success:(WLSetBlock)success failure:(WLFailureBlock)failure {
    WLPaginatedRequest* request = [WLPaginatedRequest messages:self];
    request.type = WLPaginatedRequestTypeNewer;
    request.newer = newer;
    return [request send:success failure:failure];
}

- (id)messagesOlder:(NSDate *)older newer:(NSDate *)newer success:(WLSetBlock)success failure:(WLFailureBlock)failure {
    WLPaginatedRequest* request = [WLPaginatedRequest messages:self];
    request.type = WLPaginatedRequestTypeOlder;
    request.newer = newer;
    request.older = older;
    return [request send:success failure:failure];
}

- (id)messages:(WLSetBlock)success failure:(WLFailureBlock)failure {
    WLPaginatedRequest* request = [WLPaginatedRequest messages:self];
    request.type = WLPaginatedRequestTypeFresh;
    return [request send:success failure:failure];
}

- (void)preload {
    WLHistory *history = [WLHistory historyWithWrap:self];
    [history fresh:^(NSSet *set) {
        [history.entries enumerateObjectsUsingBlock:^(WLHistoryItem* item, NSUInteger idx, BOOL *stop) {
            [item.entries enumerateObjectsUsingBlock:^(WLCandy* candy, NSUInteger idx, BOOL *stop) {
                [candy.picture fetch:nil];
                if (idx == 5) *stop = YES;
            }];
            if (idx == 4) *stop = YES;
        }];
    } failure:nil];
}

@end

@implementation WLCandy (WLAPIManager)

+ (NSNumber *)uploadingOrder {
    return @2;
}

+ (instancetype)candyWithType:(NSInteger)type wrap:(WLWrap*)wrap {
    WLCandy* candy = [self contribution];
    candy.type = type;
    return candy;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
    return [dictionary stringForKey:WLCandyUIDKey];
}

+ (void)API_prefetchDescriptors:(NSMutableDictionary *)descriptors inDictionary:(NSDictionary *)dictionary {
    [super API_prefetchDescriptors:descriptors inDictionary:dictionary];
    if (dictionary[WLCommentsKey]) {
        [WLComment API_prefetchDescriptors:descriptors inArray:dictionary[WLCommentsKey]];
    }
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    [super API_setup:dictionary container:container];
    NSInteger type = [dictionary integerForKey:WLCandyTypeKey];
    if (self.type != type) self.type = type;
    NSSet *comments = [WLComment API_entries:[dictionary arrayForKey:WLCommentsKey] container:self];
    if (![comments isSubsetOfSet:self.comments]) {
        [self addComments:comments];
    }
    if (type == WLCandyTypeVideo) {
        [self editPicture:[self.picture edit:dictionary[WLVideoURLsKey] metrics:[AssetMetrics videoMetrics]]];
    } else {
        [self editPicture:[self.picture edit:dictionary[WLImageURLsKey] metrics:[AssetMetrics imageMetrics]]];
    }
    
    NSInteger commentCount = [dictionary integerForKey:WLCommentCountKey];
    if (self.commentCount < commentCount) self.commentCount = commentCount;
    self.container = container ? : (self.wrap ? : [WLWrap entry:[dictionary stringForKey:WLWrapUIDKey]]);
    return self;
}

- (void)setEditedPictureIfNeeded:(WLAsset *)editedPicture {
    switch (self.status) {
        case WLContributionStatusReady:
            self.picture = editedPicture;
            break;
        case WLContributionStatusInProgress:
            break;
        case WLContributionStatusFinished:
            [self touch];
            self.picture = editedPicture;
            break;
        default:
            break;
    }
}

- (void)prepareForDeletion {
    [self.wrap removeCandiesObject:self];
    [super prepareForDeletion];
}

- (void)addComment:(WLComment *)comment {
    NSSet* comments = self.comments;
    self.commentCount++;
    if (!comment || [comments containsObject:comment]) {
        return;
    }
    [self addCommentsObject:comment];
    [self touch];
    [comment notifyOnAddition];
}

- (void)removeComment:(WLComment *)comment {
    NSSet* comments = self.comments;
    if ([comments containsObject:comment]) {
        [self removeCommentsObject:comment];
        if (self.commentCount > 0)  self.commentCount--;
    }
}

- (BOOL)fetched {
    return self.wrap && self.picture.original.nonempty;
}

- (id)add:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    NSMutableDictionary *metaData = [NSMutableDictionary dictionary];
    NSString* accept = [NSString stringWithFormat:@"application/vnd.ravenpod+json;version=%@",
                        [WLAPIEnvironment currentEnvironment].version];
    NSString *contributedAt = [NSString stringWithFormat:@"%f", [self.updatedAt timestamp]];
    [metaData trySetObject:accept forKey:@"Accept"];
    [metaData trySetObject:[WLAuthorization currentAuthorization].deviceUID forKey:WLDeviceIDKey];
    [metaData trySetObject:self.contributor.identifier forKey:WLUserUIDKey];
    [metaData trySetObject:self.wrap.identifier forKey:WLWrapUIDKey];
    [metaData trySetObject:self.uploadIdentifier forKey:WLUploadUIDKey];
    [metaData trySetObject:contributedAt forKey:WLContributedAtKey];
    WLComment *firstComment = [[self.comments where:@"uploading == nil"] anyObject];
    if (firstComment) {
        NSString *escapeString = [firstComment.text escapedUnicode];
        [metaData trySetObject:escapeString forKey:@"message"];
        [metaData trySetObject:firstComment.uploadIdentifier forKey:@"message_upload_uid"];
    }
    
    [self uploadWithData:metaData success:success failure:failure];
    
    return nil;
}

- (id)update:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    NSMutableDictionary *metaData = [NSMutableDictionary dictionary];
    NSString* accept = [NSString stringWithFormat:@"application/vnd.ravenpod+json;version=%@",
                        [WLAPIEnvironment currentEnvironment].version];
    NSString *editedAt = [NSString stringWithFormat:@"%f", [self.updatedAt timestamp]];
    [metaData trySetObject:accept forKey:@"Accept"];
    [metaData trySetObject:[WLAuthorization currentAuthorization].deviceUID forKey:WLDeviceIDKey];
    [metaData trySetObject:self.contributor.identifier forKey:WLUserUIDKey];
    [metaData trySetObject:self.wrap.identifier forKey:WLWrapUIDKey];
    [metaData trySetObject:self.identifier forKey:WLCandyUIDKey];
    [metaData trySetObject:editedAt forKey:WLEditedAtKey];
   
    [self uploadWithData:metaData success:success failure:failure];
    
    return nil;
}

- (void)uploadWithData:(NSDictionary *)metaData success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    __weak __typeof(self)weakSelf = self;
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = [[WLAPIEnvironment currentEnvironment] bucketUploadingIdentifier];
    uploadRequest.key = [self.picture.original lastPathComponent];
    uploadRequest.metadata = metaData;
    if (self.type == WLCandyTypeVideo) {
        uploadRequest.contentType = @"video/mp4";
    } else {
        uploadRequest.contentType = @"image/jpeg";
    }
    uploadRequest.body = [NSURL fileURLWithPath:self.picture.original];
    WLLog(@"uploading content: %@ metadata: %@", uploadRequest.contentType, metaData);
    [[[AWSS3TransferManager defaultS3TransferManager] upload:uploadRequest] continueWithBlock:^id(AWSTask *task) {
        run_in_main_queue(^{
            if(weakSelf.wrap.valid && task.completed && task.result)  {
                success(weakSelf);
            } else {
                failure(task.error);
            }
        });
        return task;
    }];
}

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    id operation = nil;
    switch (self.status) {
        case WLContributionStatusReady:
            [self remove];
            if (success) success(nil);
            break;
        case WLContributionStatusInProgress: {
            if (failure) failure([NSError errorWithDescription:WLLS(@"photo_is_uploading")]);
        } break;
        case WLContributionStatusFinished: {
            if ([self.identifier isEqualToString:self.uploadIdentifier]) {
                if (failure) failure([NSError errorWithDescription:WLLS(@"photo_is_uploading")]);
            } else {
                operation = [[WLAPIRequest deleteCandy:self] send:success failure:failure];
            }
        } break;
        default:
            break;
    }
    return operation;
}

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (self.uploaded) {
        return [[WLAPIRequest candy:self] send:success failure:failure];
    } else {
        if (failure) failure([NSError errorWithDescription:WLLS(@"photo_is_uploading")]);
        return nil;
    }
}

@end

@implementation WLMessage (WLAPIManager)

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
    return [dictionary stringForKey:@"chat_uid"];
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    [super API_setup:dictionary container:container];
    NSString* text = [dictionary stringForKey:WLContentKey];
    if (!NSStringEqual(self.text, text)) self.text = text;
    self.container = container ? : (self.wrap ? : [WLWrap entry:[dictionary stringForKey:WLWrapUIDKey]]);
    return self;
}

- (BOOL)fetched {
    return self.text.nonempty && self.wrap;
}

- (id)add:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIRequest uploadMessage:self] send:success failure:failure];
}

- (void)prepareForDeletion {
    [self.wrap removeMessagesObject:self];
    [super prepareForDeletion];
}

@end

@implementation WLComment (WLAPIManager)

+ (NSNumber *)uploadingOrder {
    return @3;
}

+ (instancetype)comment:(NSString *)text {
    WLComment* comment = [self contribution];
    comment.text = text;
    return comment;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
    return [dictionary stringForKey:WLCommentUIDKey];
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    NSString* text = [dictionary stringForKey:WLContentKey];
    if (!NSStringEqual(self.text, text)) self.text = text;
    self.container = container ? : (self.candy ? : [WLCandy entry:[dictionary stringForKey:WLCandyUIDKey]]);
    return [super API_setup:dictionary container:container];
}

- (void)prepareForDeletion {
    [self.candy removeComment:self];
    [super prepareForDeletion];
}

- (BOOL)fetched {
    return self.text.nonempty && self.candy;
}

- (id)add:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    if (self.candy.uploaded) {
        return [[WLAPIRequest postComment:self] send:success failure:failure];
    } else if (failure) {
        failure(nil);
    }
    return nil;
}

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    switch (self.status) {
        case WLContributionStatusReady:
            [self remove];
            if (success) success(nil);
            break;
        case WLContributionStatusInProgress:
            if (failure) failure([NSError errorWithDescription:WLLS(@"comment_is_uploading")]);
            break;
        case WLContributionStatusFinished: {
            switch (self.candy.status) {
                case WLContributionStatusReady:
                    [self remove];
                    if (success) success(nil);
                    break;
                case WLContributionStatusInProgress:
                    if (failure) failure([NSError errorWithDescription:WLLS(@"photo_is_uploading")]);
                    break;
                case WLContributionStatusFinished:
                    return [[WLAPIRequest deleteComment:self] send:success failure:failure];
                    break;
                default:
                    break;
            }
            return nil;
        }   break;
        default:
            break;
    }
    return nil;
}

@end
