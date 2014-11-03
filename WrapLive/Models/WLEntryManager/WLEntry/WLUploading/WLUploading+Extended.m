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
#import "AsynchronousOperation.h"
#import "WLAPIResponse.h"
#import "WLAuthorizationRequest.h"
#import "WLInternetConnectionBroadcaster.h"
#import "UIView+QuatzCoreAnimations.h"

@implementation WLUploading (Extended)

+ (instancetype)uploading:(WLContribution *)contribution {
    WLUploading* uploading = [WLUploading entry:contribution.uploadIdentifier];
    uploading.contribution = contribution;
    contribution.uploading = uploading;
    return uploading;
}

+ (NSOperationQueue*)automaticUploadingQueue {
    static NSOperationQueue* automaticUploadingQueue = nil;
    if (automaticUploadingQueue == nil) {
        automaticUploadingQueue = [[NSOperationQueue alloc] init];
        automaticUploadingQueue.maxConcurrentOperationCount = 1;
    }
    return automaticUploadingQueue;
}

+ (void)enqueueAutomaticUploading {
    [self enqueueAutomaticUploading:nil];
}

+ (void)enqueueAutomaticUploading:(WLBlock)completion {
    if (![WLInternetConnectionBroadcaster broadcaster].reachable || ![WLAuthorizationRequest authorized]) {
        if (completion) completion();
        return;
    }
    [[self automaticUploadingQueue] addAsynchronousOperationWithBlock:^(AsynchronousOperation *operation) {
        run_in_main_queue(^{
            NSOrderedSet* uploadings = [WLUploading entries];
            if (uploadings.nonempty) {
                uploadings = [uploadings mutate:^(NSMutableOrderedSet *mutableCopy) {
                    [mutableCopy sortUsingComparator:^NSComparisonResult(WLUploading* obj1, WLUploading* obj2) {
                        return [[[obj1.contribution class] uploadingOrder] compare:[[obj2.contribution class] uploadingOrder]];
                    }];
                }];
                NSOperationQueue* uploadingQueue = [[NSOperationQueue alloc] init];
                uploadingQueue.maxConcurrentOperationCount = 1;
                for (WLUploading* uploading in uploadings) {
                    [uploadingQueue addAsynchronousOperationWithBlock:^(AsynchronousOperation *_operation) {
                        run_in_main_queue(^{
                            [uploading upload:^(id object) {
                                [_operation finish:^{
                                    [operation finish:completion];
                                }];
                            } failure:^(NSError *error) {
                                [_operation finish:^{
                                    [operation finish:completion];
                                }];
                            }];
                        });
                    }];
                }
            } else {
                [operation finish:completion];
            }
        });
    }];
}

- (id)upload:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    WLContribution *contribution = self.contribution;
    if (contribution.status != WLContributionStatusReady || ![contribution canBeUploaded]) {
        failure(nil);
        return nil;
    }
    __weak typeof(self)weakSelf = self;
    self.data.operation = [self.contribution add:^(WLContribution *contribution) {
        [weakSelf removeProgressView];
        [weakSelf remove];
        success(contribution);
        [contribution notifyOnUpdate];
    } failure:^(NSError *error) {
        if (error.isDuplicatedUploading) {
            [weakSelf.contribution remove];
            failure([NSError errorWithDescription:@"This item is already uploaded."]);
        } else {
            [weakSelf.contribution notifyOnUpdate];
            failure(error);
        }
    }];
    [self.contribution notifyOnUpdate];
    return self.data.operation;
}

- (void)remove {
    self.contribution.uploading = nil;
    [super remove];
}

- (void)removeProgressView {
    UIView* progressView = self.data.progressView;
    if (progressView) {
        [UIView animateWithDuration:0.25f delay:0.25f options:0 animations:^{
            progressView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [progressView removeFromSuperview];
        }];
    }
}

@end
