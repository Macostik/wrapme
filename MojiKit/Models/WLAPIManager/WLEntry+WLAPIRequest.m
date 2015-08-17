//
//  WLAPIManager.m
//  moji
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntry+WLAPIRequest.h"
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
#import "NSUserDefaults+WLAppGroup.h"
#import "WLAlertView.h"

@implementation WLEntry (WLAPIManager)

- (BOOL)fetched {
    return YES;
}

- (BOOL)recursivelyFetched {
    WLEntry *entry = self;
    while (entry) {
        if (!entry.fetched) {
            return NO;
        }
        entry = entry.containingEntry;
    }
    return YES;
}

- (void)recursivelyFetchIfNeeded:(WLBlock)success failure:(WLFailureBlock)failure {
    
    if (self.recursivelyFetched) {
        if (success) success();
    } else {
        __weak typeof(self)weakSelf = self;
        [self fetchIfNeeded:^ (WLEntry *entry) {
            WLEntry *containingEntry = weakSelf.containingEntry;
            if (containingEntry) {
                [containingEntry recursivelyFetchIfNeeded:success failure:failure];
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

@end

@implementation WLContribution (WLAPIManager)

- (BOOL)enqueueUpdate:(WLFailureBlock)failure {
    [self notifyOnUpdate:nil];
    return [self prepareForUpdate:^(WLContribution *contribution, WLContributionStatus status) {
        switch (status) {
            case WLContributionStatusReady:
            case WLContributionStatusInProgress: break;
            case WLContributionStatusFinished: {
                [WLUploadingQueue upload:[WLUploading uploading:self type:WLEventUpdate] success:nil failure:nil];
            } break;
            default:
                break;
        }
    } failure:failure];
}

- (BOOL)prepareForUpdate:(WLContributionUpdatePreparingBlock)success failure:(WLFailureBlock)failure {
    WLContributionStatus status = self.status;
    switch (status) {
        case WLContributionStatusReady:
            if (success) success(self, status);
            return YES;
            break;
        case WLContributionStatusInProgress: {
            if (failure) failure(WLError(WLLS(@"photo_is_uploading")));
            return NO;
        } break;
        case WLContributionStatusFinished: {
            if (success) success(self, status);
            return YES;
        } break;
        default:
            return NO;
            break;
    }
}

@end

@implementation WLWrap (WLAPIManager)

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
            if (failure) failure([NSError errorWithDescription:WLLS(@"moji_is_uploading")]);
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

- (BOOL)fetched {
    return self.wrap && self.picture.original.nonempty;
}

- (id)add:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIRequest uploadCandy:self] send:success failure:failure];
}

- (id)update:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIRequest editCandy:self] send:success failure:failure];
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
            operation = [[WLAPIRequest deleteCandy:self] send:success failure:failure];
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

- (BOOL)fetched {
    return self.text.nonempty && self.wrap;
}

- (id)add:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIRequest uploadMessage:self] send:success failure:failure];
}

@end

@implementation WLComment (WLAPIManager)

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
