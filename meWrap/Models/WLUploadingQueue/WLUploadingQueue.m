//
//  WLUploadingQueue.m
//  meWrap
//
//  Created by Ravenpod on 3/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUploadingQueue.h"
#import "WLNetwork.h"
#import "WLUploading+Extended.h"
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
    WLUploadingQueue *wrapQueue = [WLUploadingQueue queueForEntriesOfClass:[Wrap class]];
    WLUploadingQueue *candyQueue = [WLUploadingQueue queueForEntriesOfClass:[Candy class]];
    [wrapQueue addDependentQueue:candyQueue];
    WLUploadingQueue *messageQueue = [WLUploadingQueue queueForEntriesOfClass:[Message class]];
    messageQueue.simultaneousUploadingsLimit = 1;
    [wrapQueue addDependentQueue:messageQueue];
    WLUploadingQueue *commentQueue = [WLUploadingQueue queueForEntriesOfClass:[Comment class]];
    [candyQueue addDependentQueue:commentQueue];
}

static NSMapTable *queues = nil;

+ (instancetype)queueForEntriesOfClass:(Class)entryClass {
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

+ (void)upload:(Uploading *)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [[self queueForEntriesOfClass:uploading.contribution.class] upload:uploading success:success failure:failure];
}

+ (void)start {
    if (![WLNetwork sharedNetwork].reachable || ![WLAuthorizationRequest authorized]) {
        return;
    }
    WLUploadingQueue *queue = [WLUploadingQueue queueForEntriesOfClass:[Wrap class]];
    [queue prepareAndStart];
}

- (void)setEntryClass:(Class)entryClass {
    _entryClass = entryClass;
    [[entryClass notifier] addReceiver:self];
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
        return [uploading.contribution isKindOfClass:self.entryClass];
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
            [self broadcast:@selector(uploadingQueueDidStart:)];
        } else {
            [self broadcast:@selector(uploadingQueueDidStop:)];
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

- (void)enqueueInternalUpload:(Uploading *)uploading queue:(WLOperationQueue*)queue success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (self.parentQueue && !self.parentQueue.isEmpty) {
        if (!self.parentQueue.isUploading) {
            [self.parentQueue prepareAndStart];
        }
        if (failure) failure(WLError(@"Parent items are uploading..."));
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
        [self broadcast:@selector(uploadingQueueDidChange:)];
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
        [self broadcast:@selector(uploadingQueueDidChange:)];
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
        [self broadcast:@selector(uploadingQueueDidChange:)];
        self.isUploading = !self.isEmpty;
    }
    for (WLUploadingQueue *queue in self.dependentQueues) {
        [queue didRemoveParentQueueContribution:entry];
    }
}

@end
