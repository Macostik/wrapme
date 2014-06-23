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
#import "WLWrapBroadcaster.h"
#import "AsynchronousOperation.h"

@implementation WLUploading (Extended)

+ (instancetype)uploading:(WLContribution *)contribution {
    WLUploading* uploading = [WLUploading entry:contribution.uploadIdentifier create:YES];
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

+ (void)enqueueAutomaticUploading:(WLBlock)completion {
    if (![WLAPIManager signedIn]) {
        if (completion) {
            completion();
        }
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
    if (self.operation || ![self.contribution canBeUploaded]) {
        failure(failure);
        return nil;
    }
    __weak typeof(self)weakSelf = self;
    self.operation = [self check:^(BOOL uploaded){
        if (uploaded) {
            [weakSelf setOperation:nil];
            weakSelf.contribution.uploading = nil;
            [weakSelf.contribution remove];
            [weakSelf.contribution broadcastRemoving];
            [weakSelf remove];
            failure([NSError errorWithDescription:@"This item is already uploaded."]);
        } else {
            weakSelf.operation = [weakSelf.contribution add:^(WLContribution *contribution) {
                [weakSelf setOperation:nil];
                [weakSelf remove];
                contribution.uploading = nil;
                [contribution save];
                [contribution broadcastChange];
                success(contribution);
            } failure:^(NSError *error) {
                [weakSelf setOperation:nil];
                [weakSelf.contribution broadcastChange];
                failure(error);
            }];
            [weakSelf.contribution broadcastChange];
        }
    } failure:^(NSError *error) {
        [weakSelf setOperation:nil];
        [weakSelf.contribution broadcastChange];
        failure(error);
    }];
    return self.operation;
}

@end
