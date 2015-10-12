//
//  WLUploading+Extended.m
//  meWrap
//
//  Created by Ravenpod on 6/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploading+Extended.h"
#import "WLEntry+API.h"
#import "WLImageCache.h"
#import "WLEntryNotifier.h"
#import "WLOperationQueue.h"
#import "WLAPIResponse.h"
#import "WLAuthorizationRequest.h"
#import "WLNetwork.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLNetwork.h"

@implementation WLUploading (Extended)

+ (instancetype)uploading:(WLContribution *)contribution {
    return [self uploading:contribution type:WLEventAdd];
}

+ (instancetype)uploading:(WLContribution *)contribution type:(WLEvent)type {
    WLUploading* uploading = [[WLUploading alloc] initWithEntity:[self entity] insertIntoManagedObjectContext:[WLEntryManager manager].context];
    uploading.type = type;
    uploading.contribution = contribution;
    contribution.uploading = uploading;
    return uploading;
}

- (void)upload:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (![WLNetwork network].reachable) {
        if (failure) failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:@{NSLocalizedDescriptionKey:@"Network connection lost."}]);
    } else {
        WLContribution *contribution = self.contribution;
        __weak typeof(self)weakSelf = self;
        [self sendTypedRequest:^(id object) {
            weakSelf.inProgress = NO;
            [weakSelf remove];
            if (success) success(object);
            [contribution notifyOnUpdate];
        } failure:^(NSError *error) {
            weakSelf.inProgress = NO;
            if (error.isDuplicatedUploading) {
                NSDictionary *data = [[error.userInfo dictionaryForKey:WLErrorResponseDataKey] objectForPossibleKeys:WLCandyKey, WLWrapKey, WLCommentKey, WLMessageKey, nil];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    [contribution API_setup:data];
                }
                [weakSelf remove];
                if (success) success(contribution);
                [contribution notifyOnUpdate];
            } else if ([error isError:WLErrorContentUnavaliable]) {
                [contribution remove];
                if (failure) failure(error);
            } else {
                [contribution notifyOnUpdate];
                if (failure) failure(error);
            }
        }];
        self.inProgress = YES;
        [contribution notifyOnUpdate];
    }
}

- (id)sendTypedRequest:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    int16_t type = self.type;
    if (type == WLEventAdd) {
        return [self add:success failure:failure];
    } else if (type == WLEventUpdate) {
        return [self update:success failure:failure];
    } else if (type == WLEventDelete) {
        return [self delete:success failure:failure];
    }
    if (failure) failure(WLError(@"Invalid uploading type"));
    return nil;
}

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    WLContribution *contribution = self.contribution;
    if (contribution.status != WLContributionStatusReady || ![contribution canBeUploaded]) {
        if (failure) failure(nil);
        return nil;
    }
    return [self.contribution add:success failure:failure];
}

- (id)update:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    WLContribution *contribution = self.contribution;
    if (!contribution.uploaded || [contribution statusOfUploadingEvent:WLEventUpdate] != WLContributionStatusReady) {
        if (failure) failure(nil);
        return nil;
    }
    return [self.contribution update:success failure:failure];
}

- (id)delete:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (success) success(nil);
    return nil;
}

- (void)remove {
    self.contribution.uploading = nil;
    [super remove];
}

@end
