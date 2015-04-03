//
//  WLUploading+Extended.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUploading+Extended.h"
#import "WLAPIManager.h"
#import "WLImageCache.h"
#import "WLEntryNotifier.h"
#import "WLOperationQueue.h"
#import "WLAPIResponse.h"
#import "WLAuthorizationRequest.h"
#import "WLNetwork.h"
#import "UIView+QuatzCoreAnimations.h"

@implementation WLUploading (Extended)

+ (instancetype)uploading:(WLContribution *)contribution {
    WLUploading* uploading = [WLUploading entry:contribution.uploadIdentifier];
    uploading.contribution = contribution;
    contribution.uploading = uploading;
    return uploading;
}

- (id)upload:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    WLContribution *contribution = self.contribution;
    if (contribution.status != WLContributionStatusReady || ![contribution canBeUploaded]) {
        if (failure) failure(nil);
        return nil;
    }
    __weak typeof(self)weakSelf = self;
    
    WLObjectBlock uploadingSuccessBlock = ^(WLContribution *contribution) {
        [weakSelf remove];
        if (success) success(contribution);
        [contribution notifyOnUpdate];
    };
    
    self.data.operation = [self.contribution add:uploadingSuccessBlock failure:^(NSError *error) {
        if (error.isDuplicatedUploading) {
            uploadingSuccessBlock(weakSelf.contribution);
        } else if ([error isError:WLErrorContentUnavaliable]) {
            [weakSelf.contribution remove];
            if (failure) failure(error);
        } else {
            [weakSelf.contribution notifyOnUpdate];
            if (failure) failure(error);
        }
    }];
    [self.contribution notifyOnUpdate];
    return self.data.operation;
}

- (void)remove {
    self.contribution.uploading = nil;
    [super remove];
}

@end
