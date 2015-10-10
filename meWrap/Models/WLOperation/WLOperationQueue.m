//
//  WLOperationQueue.m
//  meWrap
//
//  Created by Ravenpod on 3/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLOperationQueue.h"
#import "WLCollections.h"

@interface WLOperationQueue ()

@property (strong, nonatomic) NSMutableArray* operations;

@end

@implementation WLOperationQueue

static NSMutableDictionary *queues = nil;

+ (void)removeQueue:(WLOperationQueue*)queue {
    if (queue.name) {
        [queues removeObjectForKey:queue.name];
    }
}

+ (instancetype)queueNamed:(NSString*)name capacity:(NSUInteger)capacity {
    if (!queues) queues = [NSMutableDictionary dictionary];
    WLOperationQueue *queue = [queues objectForKey:name];
    if (!queue) {
        queue = queues[name] = [[self alloc] init];
        queue.name = name;
    }
    queue.capacity = capacity;
    return queue;
}

+ (instancetype)queueNamed:(NSString *)name {
    return [self queueNamed:name capacity:0];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operations = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)executingOperations {
    return [self.operations where:@"executing == YES"];
}

- (void)addOperation:(WLOperation *)operation {
    if (!operation) return;
    NSMutableArray *operations = (id)self.operations;
    if (![operations containsObject:operation]) {
        if (operations.count == 0 && self.startQueueBlock) {
            self.startQueueBlock();
        }
        operation.queue = self;
        [operations addObject:operation];
        if (self.capacity == 0 || self.executingOperations.count < self.capacity) {
            [self performSelector:@selector(startOperation:) withObject:operation afterDelay:0.0f inModes:@[NSRunLoopCommonModes]];
        }
    }
}

- (void)startOperation:(WLOperation*)operation {
    if (self.capacity == 0 || self.executingOperations.count < self.capacity) {
        [operation start];
    }
}

- (WLOperation*)addOperationWithBlock:(WLOperationBlock)block {
    WLOperation *operation = [WLOperation operationWithBlock:block];
    [self addOperation:operation];
    return operation;
}

- (void)finishOperation:(WLOperation *)operation {
    NSMutableArray *operations = (id)self.operations;
    if ([operations containsObject:operation]) {
        [operations removeObject:operation];
        for (WLOperation* _operation in operations) {
            if (!_operation.executing) {
                [self performSelector:@selector(startOperation:) withObject:_operation afterDelay:0.0f inModes:@[NSRunLoopCommonModes]];
                break;
            }
        }
        if (operations.count == 0 && self.finishQueueBlock) {
            self.finishQueueBlock();
        }
    }
}

- (void)cancelAllOperations {
    NSMutableArray *operations = (id)self.operations;
    NSArray *operationsToCancel = [operations where:@"executing == NO"];
    [operations removeObjectsInArray:operationsToCancel];
    [operationsToCancel makeObjectsPerformSelector:@selector(cancel)];
}

@end
