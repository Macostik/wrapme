//
//  WLUploadingQueue.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUploadingQueue.h"
#import "WLNetwork.h"
#import "WLUploading+Extended.h"
#import "WLAuthorizationRequest.h"
#import "WLOperationQueue.h"

@interface WLUploadingQueue ()

@property (strong, nonatomic) NSMutableOrderedSet* uploadings;

@property (strong, nonatomic) NSString* queueName;

@property (nonatomic) NSUInteger simultaneousUploadingsLimit;

@end

@implementation WLUploadingQueue

+ (void)initialize {
    WLUploadingQueue *queue = [WLUploadingQueue queueForEntriesOfClass:[WLMessage class]];
    queue.simultaneousUploadingsLimit = 1;
}

+ (NSArray*)allQueues {
    return @[[self queueForEntriesOfClass:[WLWrap class]],
             [self queueForEntriesOfClass:[WLMessage class]],
             [self queueForEntriesOfClass:[WLCandy class]],
             [self queueForEntriesOfClass:[WLComment class]]];
}

+ (instancetype)queueForEntriesOfClass:(Class)entryClass {
    static NSMapTable *queues = nil;
    if (!queues) {
        queues = [NSMapTable strongToStrongObjectsMapTable];
    }
    WLUploadingQueue *queue = [queues objectForKey:entryClass];
    if (!queue) {
        queue = [[self alloc] init];
        queue.entryClass = entryClass;
        queue.queueName = [NSString stringWithFormat:@"wl_uploading_queue_%@", [NSStringFromClass(entryClass) lowercaseString]];
        [queues setObject:queue forKey:entryClass];
    }
    return queue;
}

+ (void)upload:(WLUploading *)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [[self queueForEntriesOfClass:uploading.contribution.class] upload:uploading success:success failure:failure];
}

+ (void)start {
    [self start:nil];
}

+ (void)start:(WLBlock)completion {
    NSArray *queues = [self allQueues];
    for (WLUploadingQueue *queue in queues) {
        [queue prepare];
        runUnaryQueuedOperation(@"wl_main_uploading_queue", ^(WLOperation *operation) {
            [queue start:^{
                [operation finish:completion];
            }];
        });
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.uploadings = [NSMutableOrderedSet orderedSet];
        self.simultaneousUploadingsLimit = 3;
    }
    return self;
}

- (void)prepare {
    NSMutableOrderedSet *uploadings = [[[WLUploading entries] selectObjects:^BOOL(WLUploading* uploading) {
        return [uploading.contribution isKindOfClass:self.entryClass];
    }] mutableCopy];
    [uploadings sortByCreatedAt:NO];
    self.uploadings = uploadings;
}

- (void)prepareAndStart {
    [self prepare];
    [self start];
}

- (void)start {
    [self start:nil];
}

- (void)start:(WLBlock)completion {
    if (![WLNetwork network].reachable || ![WLAuthorizationRequest authorized]) {
        if (completion) completion();
        return;
    }
    if (self.isEmpty) {
        if (completion) completion();
    } else {
        __weak typeof(self)weakSelf = self;
        for (WLUploading* uploading in self.uploadings) {
            runQueuedOperation(self.queueName, self.simultaneousUploadingsLimit, ^(WLOperation *operation) {
                [weakSelf internalUpload:uploading success:^(id object) {
                    [operation finish:completion];
                } failure:^(NSError *error) {
                    [operation finish:completion];
                }];
            });
        }
    }
}

- (void)setIsUploading:(BOOL)isUploading {
    if (_isUploading != isUploading) {
        _isUploading = isUploading;
        if (isUploading) {
            [self broadcast:@selector(uploadingQueueDidStart:)];
        } else {
            [self broadcast:@selector(uploadingQueueDidStop:)];
        }
    }
}

- (void)internalUpload:(WLUploading*)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    self.isUploading = YES;
    [self addUploading:uploading];
    __weak typeof(self)weakSelf = self;
    [uploading upload:^(id object) {
        [weakSelf.uploadings removeObject:uploading];
        if (success) success(object);
        [weakSelf broadcast:@selector(uploadingQueueDidChange:)];
        weakSelf.isUploading = !weakSelf.isEmpty;
    } failure:^(NSError *error) {
        if (!uploading.contribution.valid) {
            [weakSelf.uploadings removeObject:uploading];
        }
        if (failure) failure(error);
        [weakSelf broadcast:@selector(uploadingQueueDidChange:)];
        weakSelf.isUploading = !weakSelf.isEmpty;
    }];
}

- (void)addUploading:(WLUploading*)uploading {
    if (![self.uploadings containsObject:uploading]) {
        [self.uploadings addObject:uploading];
        [self broadcast:@selector(uploadingQueueDidChange:)];
    }
}

- (void)upload:(WLUploading*)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self addUploading:uploading];
    runQueuedOperation(self.queueName, self.simultaneousUploadingsLimit, ^(WLOperation *operation) {
        [weakSelf internalUpload:uploading success:^(id object) {
            [operation finish];
            if (success) success(object);
        } failure:^(NSError *error) {
            [operation finish];
            if (failure) failure(error);
        }];
    });
}

- (BOOL)isEmpty {
    return self.count == 0;
}

- (NSUInteger)count {
    return self.uploadings.count;
}

@end
