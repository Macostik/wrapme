//
//  WLAPIManager.m
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollections.h"
#import "WLAddressBook.h"
#import "WLWelcomeViewController.h"
#import "WLImageCache.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAuthorizationRequest.h"
#import "WLOperationQueue.h"
#import "WLHistory.h"
#import <AWSS3/AWSS3.h>

@implementation Entry (WLAPIManager)

+ (NSArray*)prefetchArray:(NSArray *)array {
    NSMutableDictionary *descriptors = [NSMutableDictionary dictionary];
    [self prefetchDescriptors:descriptors inArray:array];
    [EntryContext.sharedContext fetchEntries:[descriptors allValues]];
    return array;
}

+ (NSDictionary*)prefetchDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *descriptors = [NSMutableDictionary dictionary];
    [self prefetchDescriptors:descriptors inDictionary:dictionary];
    [EntryContext.sharedContext fetchEntries:[descriptors allValues]];
    return dictionary;
}

+ (void)prefetchDescriptors:(NSMutableDictionary*)descriptors inArray:(NSArray*)array {
    for (NSDictionary *dictionary in array) {
        [self prefetchDescriptors:descriptors inDictionary:dictionary];
    }
}

+ (void)prefetchDescriptors:(NSMutableDictionary*)descriptors inDictionary:(NSDictionary*)dictionary {
    NSString *uid = [self uid:dictionary];
    if (uid && [descriptors objectForKey:uid] == nil) {
        EntryDescriptor *descriptor = [[EntryDescriptor alloc] initWithName:[self entityName] uid:uid];
        descriptor.locuid = [self locuid:dictionary];
        [descriptors setObject:descriptor forKey:uid];
    }
}

- (instancetype)update:(NSDictionary *)dictionary {
    [self map:dictionary container:nil];
    if (self.updated) {
        [self notifyOnUpdate:EntryUpdateEventDefault];
    }
    return self;
}

- (BOOL)fetched {
    return YES;
}

- (BOOL)recursivelyFetched {
    Entry *entry = self;
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
        [self fetchIfNeeded:^ (Entry *entry) {
            Entry *container = weakSelf.container;
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

@end

@implementation User (WLAPIManager)


@end

@implementation Device (WLAPIManager)

@end

@implementation Contribution (WLAPIManager)

+ (void)prefetchDescriptors:(NSMutableDictionary *)descriptors inDictionary:(NSDictionary *)dictionary {
    [super prefetchDescriptors:descriptors inDictionary:dictionary];
    
    if (dictionary[WLContributorKey]) {
        [User prefetchDescriptors:descriptors inDictionary:dictionary[WLContributorKey]];
    }
    
    if (dictionary[WLEditorKey]) {
        [User prefetchDescriptors:descriptors inDictionary:dictionary[WLEditorKey]];
    }
}

+ (NSNumber *)uploadingOrder {
    return @5;
}

@end

@implementation Wrap (WLAPIManager)

+ (NSNumber *)uploadingOrder {
    return @1;
}

+ (void)prefetchDescriptors:(NSMutableDictionary *)descriptors inDictionary:(NSDictionary *)dictionary {
    [super prefetchDescriptors:descriptors inDictionary:dictionary];
    
    if (dictionary[WLContributorsKey]) {
        [User prefetchDescriptors:descriptors inArray:dictionary[WLContributorsKey]];
    }
    
    if (dictionary[WLCreatorKey] != nil) {
        [User prefetchDescriptors:descriptors inDictionary:dictionary[WLCreatorKey]];
    }
    
    if (dictionary[WLCandiesKey] != nil) {
        [Candy prefetchDescriptors:descriptors inArray:dictionary[WLCandiesKey]];
    }
}

- (BOOL)fetched {
    return self.name.nonempty && self.contributor;
}

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure {
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
            if (failure) failure([NSError errorWithDescription:@"wrap_is_uploading".ls]);
            break;
        case WLContributionStatusFinished: {
            operation = [[WLAPIRequest deleteWrap:self] send:success failure:failure];
        }   break;
        default:
            break;
    }
    return operation;
}

- (id)fetch:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    return [self fetch:WLWrapContentTypeRecent success:success failure:failure];
}

- (id)fetch:(NSString*)contentType success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    if (self.uploaded) {
        return [[WLPaginatedRequest wrap:self contentType:contentType] send:success failure:failure];
    } else if (success) {
        success(nil);
    }
    return nil;
}

- (id)update:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIRequest updateWrap:self] send:success failure:failure];
}

- (id)messagesNewer:(NSDate *)newer success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    WLPaginatedRequest* request = [WLPaginatedRequest messages:self];
    request.type = WLPaginatedRequestTypeNewer;
    request.newer = newer;
    return [request send:success failure:failure];
}

- (id)messagesOlder:(NSDate *)older newer:(NSDate *)newer success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    WLPaginatedRequest* request = [WLPaginatedRequest messages:self];
    request.type = WLPaginatedRequestTypeOlder;
    request.newer = newer;
    request.older = older;
    return [request send:success failure:failure];
}

- (id)messages:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    WLPaginatedRequest* request = [WLPaginatedRequest messages:self];
    request.type = WLPaginatedRequestTypeFresh;
    return [request send:success failure:failure];
}

- (void)preload {
    WLHistory *history = [WLHistory historyWithWrap:self];
    [history fresh:^(NSArray *array) {
        [history.entries enumerateObjectsUsingBlock:^(Candy *candy, NSUInteger idx, BOOL *stop) {
            [candy.picture fetch:nil];
            if (idx == 20) *stop = YES;
        }];
    } failure:nil];
}

@end

@implementation Candy (WLAPIManager)

+ (NSNumber *)uploadingOrder {
    return @2;
}

+ (void)prefetchDescriptors:(NSMutableDictionary *)descriptors inDictionary:(NSDictionary *)dictionary {
    [super prefetchDescriptors:descriptors inDictionary:dictionary];
    if (dictionary[WLCommentsKey]) {
        [Comment prefetchDescriptors:descriptors inArray:dictionary[WLCommentsKey]];
    }
}

- (void)setEditedPictureIfNeeded:(Asset *)editedPicture {
    switch (self.status) {
        case WLContributionStatusReady:
            self.picture = editedPicture;
            break;
        case WLContributionStatusInProgress:
            break;
        case WLContributionStatusFinished:
            [self touch];
            self.editedAt = [NSDate now];
            self.editor = [User currentUser];
            self.picture = editedPicture;
            break;
        default:
            break;
    }
}

- (void)prepareForDeletion {
    self.wrap = nil;
    [super prepareForDeletion];
}

- (BOOL)fetched {
    return self.wrap && self.picture.original.nonempty;
}

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    NSMutableDictionary *metaData = [NSMutableDictionary dictionary];
    NSString* accept = [NSString stringWithFormat:@"application/vnd.ravenpod+json;version=%@",
                        [WLAPIEnvironment currentEnvironment].version];
    NSString *contributedAt = [NSString stringWithFormat:@"%f", [self.updatedAt timestamp]];
    [metaData trySetObject:accept forKey:@"Accept"];
    [metaData trySetObject:[Authorization currentAuthorization].deviceUID forKey:WLDeviceIDKey];
    [metaData trySetObject:self.contributor.identifier forKey:WLUserUIDKey];
    [metaData trySetObject:self.wrap.identifier forKey:WLWrapUIDKey];
    [metaData trySetObject:self.uploadIdentifier forKey:WLUploadUIDKey];
    [metaData trySetObject:contributedAt forKey:WLContributedAtKey];
    Comment *firstComment = [[self.comments where:@"uploading == nil"] anyObject];
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
    [metaData trySetObject:[Authorization currentAuthorization].deviceUID forKey:WLDeviceIDKey];
    [metaData trySetObject:[User currentUser].identifier forKey:WLUserUIDKey];
    [metaData trySetObject:self.wrap.identifier forKey:WLWrapUIDKey];
    [metaData trySetObject:self.identifier forKey:WLCandyUIDKey];
    [metaData trySetObject:editedAt forKey:WLEditedAtKey];
   
    [self uploadWithData:metaData success:success failure:failure];
    
    return nil;
}

- (void)uploadWithData:(NSDictionary *)metaData success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if ([self.picture.original hasPrefix:@"http"]) {
        if (success) success(self);
        return;
    }
    __weak __typeof(self)weakSelf = self;
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = [[WLAPIEnvironment currentEnvironment] bucketUploadingIdentifier];
    uploadRequest.key = [self.picture.original lastPathComponent];
    uploadRequest.metadata = metaData;
    if (self.type == MediaTypeVideo) {
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
            if (failure) failure([NSError errorWithDescription:(self.isVideo ? @"video_is_uploading" : @"photo_is_uploading").ls]);
        } break;
        case WLContributionStatusFinished: {
            if ([self.identifier isEqualToString:self.uploadIdentifier]) {
                if (failure) failure([NSError errorWithDescription:@"publishing_in_progress".ls]);
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
        if (failure) failure([NSError errorWithDescription:(self.isVideo ? @"video_is_uploading" : @"photo_is_uploading").ls]);
        return nil;
    }
}

- (void)download:(WLBlock)success failure:(WLFailureBlock)failure {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied) {
        if (failure) failure(WLError(@"downloading_privacy_settings".ls));
    } else {
        __weak typeof(self)weakSelf = self;
        if (weakSelf.type == MediaTypeVideo) {
            NSString *url = weakSelf.picture.original;
            if ([[NSFileManager defaultManager] fileExistsAtPath:url]) {
                [PHPhotoLibrary addAsset:^PHAssetChangeRequest *{
                    return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:url]];
                } collectionTitle:[Constants albumName] success:success failure:failure];
            } else {
                NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    if (error) {
                        if (failure) failure(error);
                    } else {
                        NSURL* url = [[location URLByDeletingPathExtension] URLByAppendingPathExtension:@"mp4"];
                        [[NSFileManager defaultManager] moveItemAtURL:location toURL:url error:nil];
                        [PHPhotoLibrary addAsset:^PHAssetChangeRequest *{
                            return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
                        } collectionTitle:[Constants albumName] success:success failure:failure];
                    }
                }];
                [task resume];
            }
        } else {
            [[WLBlockImageFetching fetchingWithUrl:weakSelf.picture.original] enqueue:^(UIImage *image) {
                [PHPhotoLibrary addAsset:^PHAssetChangeRequest *{
                    return [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                } collectionTitle:[Constants albumName] success:success failure:failure];
            } failure:failure];
        }
    }
}

@end

@implementation Message (WLAPIManager)

- (BOOL)fetched {
    return self.text.nonempty && self.wrap;
}

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIRequest uploadMessage:self] send:success failure:failure];
}

- (void)prepareForDeletion {
    self.wrap = nil;
    [super prepareForDeletion];
}

@end

@implementation Comment (WLAPIManager)

+ (NSNumber *)uploadingOrder {
    return @3;
}

+ (instancetype)comment:(NSString *)text {
    Comment *comment = [self contribution];
    comment.text = text;
    return comment;
}

- (void)prepareForDeletion {
    self.candy = nil;
    [super prepareForDeletion];
}

- (BOOL)fetched {
    return self.text.nonempty && self.candy;
}

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure {
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
            if (failure) failure([NSError errorWithDescription:@"comment_is_uploading".ls]);
            break;
        case WLContributionStatusFinished: {
            switch (self.candy.status) {
                case WLContributionStatusReady:
                    [self remove];
                    if (success) success(nil);
                    break;
                case WLContributionStatusInProgress:
                    if (failure) failure([NSError errorWithDescription:(self.candy.isVideo ? @"video_is_uploading" : @"photo_is_uploading").ls]);
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

@implementation NSString (Unicode)

- (NSString *)escapedUnicode {
    NSData* data = [self dataUsingEncoding:NSUTF32LittleEndianStringEncoding allowLossyConversion:YES];
    size_t bytesRead = 0;
    const char* bytes = data.bytes;
    NSMutableString* encodedString = [NSMutableString string];
    while (bytesRead < data.length){
        uint32_t codepoint = *((uint32_t*) &bytes[bytesRead]);
        if (codepoint > 0x007E) {
            [self getBytes:&codepoint
                 maxLength:4
                usedLength:nil
                  encoding:NSUTF32StringEncoding
                   options:0
                     range:NSMakeRange(0, 0)
            remainingRange:nil];
            [encodedString appendFormat:@"\\u{%04x}", codepoint];
        }
        else {
            [encodedString appendFormat:@"%C", (unichar)codepoint];
        }
        bytesRead += sizeof(uint32_t);
    }
    
    return encodedString;
}

@end
