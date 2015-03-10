//
//  WLOperationQueue.h
//  WrapLive
//
//  Created by Sergey Maximenko on 3/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLOperation.h"

@interface WLOperationQueue : NSObject

@property (strong, nonatomic) NSString *name;

@property (readonly, nonatomic) NSArray* operations;

@property (readonly, nonatomic) NSArray* executingOperations;

@property (nonatomic) NSUInteger capacity;

+ (instancetype)queueNamed:(NSString*)name;

+ (instancetype)queueNamed:(NSString*)name capacity:(NSUInteger)capacity;

- (void)addOperation:(WLOperation*)operation;

- (WLOperation*)addOperationWithBlock:(WLOperationBlock)block;

- (void)finishOperation:(WLOperation*)operation;

@end

static inline WLOperation* runQueuedOperation (NSString *queue, NSUInteger capacity, WLOperationBlock block) {
    return [[WLOperationQueue queueNamed:queue capacity:capacity] addOperationWithBlock:block];
};

static inline NSArray* runQueuedOperations (NSString *queue, NSUInteger capacity, WLOperationBlock block, ...) {
    va_list args;
    va_start(args, block);
    NSMutableArray* operations = [NSMutableArray array];
    for (; block != nil; block = va_arg(args, id)) {
        [operations addObject:runQueuedOperation(queue, capacity, block)];
    }
    va_end(args);
    return [operations copy];
};

static inline WLOperation* runDefaultQueuedOperation (NSString *queue, WLOperationBlock block) {
    return runQueuedOperation(queue, 0, block);
};

static inline NSArray* runDefaultQueuedOperations (NSString *queue, WLOperationBlock block, ...) {
    va_list args;
    va_start(args, block);
    NSMutableArray* operations = [NSMutableArray array];
    for (; block != nil; block = va_arg(args, id)) {
        [operations addObject:runDefaultQueuedOperation(queue, block)];
    }
    va_end(args);
    return [operations copy];
};

static inline WLOperation* runUnaryQueuedOperation (NSString *queue, WLOperationBlock block) {
    return runQueuedOperation(queue, 1, block);
};

static inline NSArray* runUnaryQueuedOperations (NSString *queue, WLOperationBlock block, ...) {
    va_list args;
    va_start(args, block);
    NSMutableArray* operations = [NSMutableArray array];
    for (; block != nil; block = va_arg(args, id)) {
        [operations addObject:runUnaryQueuedOperation(queue, block)];
    }
    va_end(args);
    return [operations copy];
};
