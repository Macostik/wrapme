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

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (success) success(self);
    return nil;
}

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

@end

@implementation Wrap (WLAPIManager)

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

+ (void)prefetchDescriptors:(NSMutableDictionary *)descriptors inDictionary:(NSDictionary *)dictionary {
    [super prefetchDescriptors:descriptors inDictionary:dictionary];
    if (dictionary[WLCommentsKey]) {
        [Comment prefetchDescriptors:descriptors inArray:dictionary[WLCommentsKey]];
    }
}

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (self.uploaded) {
        return [[WLAPIRequest candy:self] send:success failure:failure];
    } else {
        if (failure) failure([[NSError alloc] initWithMessage:(self.isVideo ? @"video_is_uploading" : @"photo_is_uploading").ls]);
        return nil;
    }
}

- (void)download:(WLBlock)success failure:(WLFailureBlock)failure {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied) {
        if (failure) failure([[NSError alloc] initWithMessage:@"downloading_privacy_settings".ls]);
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
                        run_in_main_queue(^{
                            if (failure) failure(error);
                        });
                    } else {
                        NSURL* url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"Documents/%@.mp4", [NSString GUID]]];
                        [[NSFileManager defaultManager] moveItemAtURL:location toURL:url error:nil];
                        run_in_main_queue(^{
                            NSError *reachabilityError = nil;
                            [url checkResourceIsReachableAndReturnError:&reachabilityError];
                            if (reachabilityError) {
                                if (failure) failure(reachabilityError);
                            } else {
                                [PHPhotoLibrary addAsset:^PHAssetChangeRequest *{
                                    return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
                                } collectionTitle:[Constants albumName] success:^{
                                    [[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
                                    if (success) success();
                                } failure:^(NSError * _Nullable error) {
                                    [[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
                                    if (failure) failure(error);
                                }];
                            }
                        });
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
