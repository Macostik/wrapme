//
//  WLOperationQueue.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLOperationQueue.h"
#import "NSArray+Additions.h"

@interface WLOperationQueue ()

@property (strong, nonatomic) NSMutableArray* operations;

@end

@implementation WLOperationQueue

+ (instancetype)queueNamed:(NSString*)name capacity:(NSUInteger)capacity {
    static NSMutableDictionary *queues = nil;
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
    return [self.operations objectsWhere:@"executing == YES"];
}

- (void)addOperation:(WLOperation *)operation {
    if (!operation) return;
    NSMutableArray *operations = (id)self.operations;
    if (![operations containsObject:operation]) {
        operation.queue = self;
        [operations addObject:operation];
        if (self.capacity == 0 || self.executingOperations.count < self.capacity) {
            [self performSelector:@selector(startOperation:) withObject:operation afterDelay:0.0f];
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
                [self performSelector:@selector(startOperation:) withObject:_operation afterDelay:0.0f];
                break;
            }
        }
    }
}

@end
