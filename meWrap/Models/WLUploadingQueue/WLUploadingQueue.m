//
//  WLUploadingQueue.m
//  meWrap
//
//  Created by Ravenpod on 3/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUploadingQueue.h"
#import "WLNetwork.h"
#import "WLAuthorizationRequest.h"
#import "WLOperationQueue.h"

@interface WLUploadingQueue () <EntryNotifying>

@property (strong, nonatomic) NSMutableOrderedSet* uploadings;

@property (strong, nonatomic) NSString* queueName;

@property (nonatomic) NSUInteger simultaneousUploadingsLimit;

@property (strong, nonatomic) NSMutableSet* dependentQueues;

@property (weak, nonatomic) WLUploadingQueue *parentQueue;

@end

@implementation WLUploadingQueue

+ (void)initialize {
    WLUploadingQueue *wrapQueue = [WLUploadingQueue queueForEntityName:[Wrap entityName]];
    WLUploadingQueue *candyQueue = [WLUploadingQueue queueForEntityName:[Candy entityName]];
    [wrapQueue addDependentQueue:candyQueue];
    WLUploadingQueue *messageQueue = [WLUploadingQueue queueForEntityName:[Message entityName]];
    messageQueue.simultaneousUploadingsLimit = 1;
    [wrapQueue addDependentQueue:messageQueue];
    WLUploadingQueue *commentQueue = [WLUploadingQueue queueForEntityName:[Comment entityName]];
    [candyQueue addDependentQueue:commentQueue];
}

static NSMapTable *queues = nil;

+ (instancetype)queueForEntityName:(NSString *)entityName {
    if (!queues) {
        queues = [NSMapTable strongToStrongObjectsMapTable];
    }
    WLUploadingQueue *queue = [queues objectForKey:entityName];
    if (!queue) {
        queue = [[self alloc] init];
        queue.entityName = entityName;
        queue.queueName = [NSString stringWithFormat:@"wl_uploading_queue_%@", [entityName lowercaseString]];
        [queues setObject:queue forKey:entityName];
    }
    return queue;
}

+ (void)upload:(Uploading *)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [[self queueForEntityName:uploading.contribution.entity.name] upload:uploading success:success failure:failure];
}

+ (void)start {
    if (![WLNetwork sharedNetwork].reachable || ![WLAuthorizationRequest authorized]) {
        return;
    }
    WLUploadingQueue *queue = [WLUploadingQueue queueForEntityName:[Wrap entityName]];
    [queue prepareAndStart];
}

- (void)setEntityName:(NSString *)entityName {
    _entityName = entityName;
    [[EntryNotifier notifierForName:entityName] addReceiver:self];
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
    NSMutableOrderedSet *uploadings = [[[[Uploading entries] selects:^BOOL(Uploading *uploading) {
        return [uploading.contribution.entity.name isEqualToString:self.entityName];
    }] orderedSet] mutableCopy];
    [uploadings sortByCreatedAt:NO];
    self.uploadings = uploadings;
}

- (void)prepareAndStart {
    [self prepare];
    [self start];
}

- (void)start {
    if (![WLNetwork sharedNetwork].reachable || ![WLAuthorizationRequest authorized]) {
        return;
    }
    if (self.isEmpty) {
        [self finish];
    } else {
        WLOperationQueue *queue = [WLOperationQueue queueNamed:self.queueName capacity:self.simultaneousUploadingsLimit];
        for (Uploading *uploading in self.uploadings) {
            [self enqueueInternalUpload:uploading queue:queue success:nil failure:nil];
        }
    }
}

- (void)finish {
    if (self.isEmpty && [WLNetwork sharedNetwork].reachable) {
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

- (void)internalUpload:(Uploading *)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
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

- (void)enqueueInternalUpload:(Uploading *)uploading queue:(WLOperationQueue*)queue success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (self.parentQueue && !self.parentQueue.isEmpty) {
        if (!self.parentQueue.isUploading) {
            [self.parentQueue prepareAndStart];
        }
        if (failure) failure([[NSError alloc] initWithMessage:@"Parent items are uploading..."]);
        return;
    }
    __weak typeof(self)weakSelf = self;
    
    queue.finishQueueBlock = ^ {
        [weakSelf finish];
    };
    
    [queue addOperationWithBlock:^(WLOperation *operation) {
        [weakSelf internalUpload:uploading success:^(id object) {
            [operation finish];
            if (success) success(object);
        } failure:^(NSError *error) {
            [operation finish];
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

- (void)upload:(Uploading *)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [self addUploading:uploading];
    [self enqueueInternalUpload:uploading queue:[WLOperationQueue queueNamed:self.queueName capacity:self.simultaneousUploadingsLimit] success:success failure:failure];
}

- (BOOL)isEmpty {
    return self.count == 0;
}

- (NSUInteger)count {
    return self.uploadings.count;
}

- (void)addDependentQueue:(WLUploadingQueue *)queue {
    if (queue) {
        if (!self.dependentQueues) {
            self.dependentQueues = [NSMutableSet setWithObject:queue];
        } else {
            [self.dependentQueues addObject:queue];
        }
        queue.parentQueue = self;
    }
}

- (void)didRemoveParentQueueContribution:(Contribution *)contribution {
    NSMutableSet *removedUploadins = [NSMutableSet set];
    for (Uploading *_uploading in self.uploadings) {
        if (_uploading.contribution.container == contribution) {
            _uploading.inProgress = NO;
            [removedUploadins addObject:_uploading];
        }
    }
    if (removedUploadins.count > 0) {
        [self.uploadings minusSet:removedUploadins];
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
