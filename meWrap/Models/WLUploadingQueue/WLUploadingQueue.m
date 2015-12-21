//
//  WLUploadingQueue.m
//  meWrap
//
//  Created by Ravenpod on 3/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUploadingQueue.h"

@interface WLUploadingQueue () <EntryNotifying>

@property (strong, nonatomic) NSMutableArray* uploadings;

@property (nonatomic) NSUInteger simultaneousUploadingsLimit;

@property (strong, nonatomic) NSMutableSet* dependentQueues;

@property (weak, nonatomic) WLUploadingQueue *parentQueue;

@property (strong, nonatomic) RunQueue *runQueue;

@end

@implementation WLUploadingQueue

+ (void)initialize {
    WLUploadingQueue *wrapQueue = [WLUploadingQueue defaultQueueForEntityName:[Wrap entityName]];
    WLUploadingQueue *candyQueue = [WLUploadingQueue defaultQueueForEntityName:[Candy entityName]];
    [wrapQueue addDependentQueue:candyQueue];
    WLUploadingQueue *messageQueue = [WLUploadingQueue defaultQueueForEntityName:[Message entityName]];
    messageQueue.simultaneousUploadingsLimit = 1;
    [wrapQueue addDependentQueue:messageQueue];
    WLUploadingQueue *commentQueue = [WLUploadingQueue defaultQueueForEntityName:[Comment entityName]];
    [candyQueue addDependentQueue:commentQueue];
}

static NSMapTable *queues = nil;

+ (instancetype)defaultQueueForEntityName:(NSString *)entityName {
    if (!queues) {
        queues = [NSMapTable strongToStrongObjectsMapTable];
    }
    WLUploadingQueue *queue = [queues objectForKey:entityName];
    if (!queue) {
        queue = [[self alloc] init];
        queue.entityName = entityName;
        [queues setObject:queue forKey:entityName];
    }
    return queue;
}

+ (void)upload:(Uploading *)uploading {
    [self upload:uploading success:nil failure:nil];
}

+ (void)upload:(Uploading *)uploading success:(ObjectBlock)success failure:(FailureBlock)failure {
    [[self defaultQueueForEntityName:uploading.contribution.entity.name] upload:uploading success:success failure:failure];
}

+ (void)start {
    if (![Network sharedNetwork].reachable || ![Authorization active]) {
        return;
    }
    WLUploadingQueue *queue = [WLUploadingQueue defaultQueueForEntityName:[Wrap entityName]];
    [queue prepareAndStart];
}

- (void)setEntityName:(NSString *)entityName {
    _entityName = entityName;
    [[EntryNotifier notifierForName:entityName] addReceiver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.uploadings = [NSMutableArray array];
        self.dependentQueues = [NSMutableSet set];
        self.runQueue = [[RunQueue alloc] init];
        self.simultaneousUploadingsLimit = 3;
    }
    return self;
}

- (void)setSimultaneousUploadingsLimit:(NSUInteger)simultaneousUploadingsLimit {
    _simultaneousUploadingsLimit = simultaneousUploadingsLimit;
    self.runQueue.limit = simultaneousUploadingsLimit;
}

- (void)prepare {
    NSArray *contributions = [[[[NSFetchRequest fetch:self.entityName] queryString:@"uploading != nil"] sort:@"createdAt" asc:YES] execute];
    self.uploadings = [[contributions map:^id _Nullable(Contribution *contribution) {
        return contribution.uploading;
    }] mutableCopy];
}

- (void)prepareAndStart {
    [self prepare];
    [self start];
}

- (void)start {
    if (![Network sharedNetwork].reachable || ![Authorization active]) {
        return;
    }
    if (self.isEmpty) {
        [self finish];
    } else {
        for (Uploading *uploading in self.uploadings) {
            [self enqueueInternalUpload:uploading success:nil failure:nil];
        }
    }
}

- (void)finish {
    if (self.isEmpty && [Network sharedNetwork].reachable) {
        for (WLUploadingQueue *queue in self.dependentQueues) {
            [queue prepareAndStart];
        }
    }
}

- (void)setIsUploading:(BOOL)isUploading {
    if (_isUploading != isUploading) {
        _isUploading = isUploading;
        if (isUploading) {
            for (id receiver in [self broadcastReceivers]) {
                if ([receiver respondsToSelector:@selector(uploadingQueueDidStart:)]) {
                    [receiver uploadingQueueDidStart:self];
                }
            }
        } else {
            for (id receiver in [self broadcastReceivers]) {
                if ([receiver respondsToSelector:@selector(uploadingQueueDidStop:)]) {
                    [receiver uploadingQueueDidStop:self];
                }
            }
        }
    }
}

- (void)internalUpload:(Uploading *)uploading success:(ObjectBlock)success failure:(FailureBlock)failure {
    self.isUploading = YES;
    [self addUploading:uploading];
    __weak typeof(self)weakSelf = self;
    [uploading upload:^(id object) {
        [weakSelf.uploadings removeObject:uploading];
        if (success) success(object);
        for (id receiver in [self broadcastReceivers]) {
            if ([receiver respondsToSelector:@selector(uploadingQueueDidChange:)]) {
                [receiver uploadingQueueDidChange:self];
            }
        }
        weakSelf.isUploading = !weakSelf.isEmpty;
    } failure:^(NSError *error) {
        if (!uploading.contribution.valid) {
            [weakSelf.uploadings removeObject:uploading];
        }
        if (failure) failure(error);
        for (id receiver in [self broadcastReceivers]) {
            if ([receiver respondsToSelector:@selector(uploadingQueueDidChange:)]) {
                [receiver uploadingQueueDidChange:self];
            }
        }
        weakSelf.isUploading = !weakSelf.isEmpty;
    }];
}

- (void)enqueueInternalUpload:(Uploading *)uploading success:(ObjectBlock)success failure:(FailureBlock)failure {
    if (self.parentQueue && !self.parentQueue.isEmpty) {
        if (!self.parentQueue.isUploading) {
            [self.parentQueue prepareAndStart];
        }
        if (failure) failure([[NSError alloc] initWithMessage:@"Parent items are uploading..."]);
        return;
    }
    __weak typeof(self)weakSelf = self;
    
    self.runQueue.didFinish = ^ {
        [weakSelf finish];
    };
    
    [self.runQueue run:^(Block finish) {
        [weakSelf internalUpload:uploading success:^(id object) {
            finish();
            if (success) success(object);
        } failure:^(NSError *error) {
            finish();
            if (failure) failure(error);
        }];
    }];
}

- (void)addUploading:(Uploading *)uploading {
    if (![self.uploadings containsObject:uploading]) {
        [self.uploadings addObject:uploading];
        for (id receiver in [self broadcastReceivers]) {
            if ([receiver respondsToSelector:@selector(uploadingQueueDidChange:)]) {
                [receiver uploadingQueueDidChange:self];
            }
        }
    }
}

- (void)upload:(Uploading *)uploading success:(ObjectBlock)success failure:(FailureBlock)failure {
    [self addUploading:uploading];
    [self enqueueInternalUpload:uploading success:success failure:failure];
}

- (BOOL)isEmpty {
    return self.count == 0;
}

- (NSUInteger)count {
    return self.uploadings.count;
}

- (void)addDependentQueue:(WLUploadingQueue *)queue {
    if (queue) {
        [self.dependentQueues addObject:queue];
        queue.parentQueue = self;
    }
}

- (void)didRemoveParentQueueContribution:(Contribution *)contribution {
    NSMutableArray *removedUploadins = [NSMutableArray array];
    for (Uploading *_uploading in self.uploadings) {
        if (_uploading.contribution.container == contribution) {
            _uploading.inProgress = NO;
            [removedUploadins addObject:_uploading];
        }
    }
    if (removedUploadins.count > 0) {
        [self.uploadings removeObjectsInArray:removedUploadins];
        for (id receiver in [self broadcastReceivers]) {
            if ([receiver respondsToSelector:@selector(uploadingQueueDidChange:)]) {
                [receiver uploadingQueueDidChange:self];
            }
        }
        self.isUploading = !self.isEmpty;
        
        for (Uploading *uploading in removedUploadins) {
            for (WLUploadingQueue *queue in self.dependentQueues) {
                [queue didRemoveParentQueueContribution:uploading.contribution];
            }
        }
    }
}

// MARK: - EntryNotifying

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return entry.valid;
}

- (void)notifier:(EntryNotifier *)notifier willDeleteEntry:(Contribution *)entry {
    Uploading *uploading = [(Contribution *)entry uploading];
    if ([self.uploadings containsObject:uploading]) {
        [self.uploadings removeObject:uploading];
        for (id receiver in [self broadcastReceivers]) {
            if ([receiver respondsToSelector:@selector(uploadingQueueDidChange:)]) {
                [receiver uploadingQueueDidChange:self];
            }
        }
        self.isUploading = !self.isEmpty;
    }
    for (WLUploadingQueue *queue in self.dependentQueues) {
        [queue didRemoveParentQueueContribution:entry];
    }
}

@end
