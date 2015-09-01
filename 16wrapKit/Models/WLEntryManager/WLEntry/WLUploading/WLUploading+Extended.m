//
//  WLUploading+Extended.m
//  moji
//
//  Created by Ravenpod on 6/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploading+Extended.h"
#import "WLEntry+WLAPIRequest.h"
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
    WLUploading* uploading = [WLUploading entry:contribution.uploadIdentifier];
    uploading.type = type;
    uploading.contribution = contribution;
    contribution.uploading = uploading;
    return uploading;
}

- (id)upload:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (![WLNetwork network].reachable) {
        if (failure) failure([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:@{NSLocalizedDescriptionKey:@"Network connection lost."}]);
        return nil;
    }
    WLContribution *contribution = self.contribution;
    __weak typeof(self)weakSelf = self;
    self.data.operation = [self sendTypedRequest:^(id object) {
        [weakSelf remove];
        if (success) success(object);
        [contribution notifyOnUpdate:nil];
    } failure:^(NSError *error) {
        if (error.isDuplicatedUploading) {
            NSDictionary *data = [[error.userInfo dictionaryForKey:WLErrorResponseDataKey] objectForPossibleKeys:WLCandyKey, WLWrapKey, WLCommentKey, WLMessageKey, nil];
            if ([data isKindOfClass:[NSDictionary class]]) {
                [weakSelf.contribution API_setup:data];
            }
            [weakSelf remove];
            if (success) success(contribution);
            [contribution notifyOnUpdate:nil];
        } else if ([error isError:WLErrorContentUnavaliable]) {
            [weakSelf.contribution remove];
            if (failure) failure(error);
        } else {
            [weakSelf.contribution notifyOnUpdate:nil];
            if (failure) failure(error);
        }
    }];
    [contribution notifyOnUpdate:nil];
    return self.data.operation;
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
