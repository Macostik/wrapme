//
//  PGPublishOperation.h
//  Pressgram
//
//  Created by Sergey Maximenko on 10.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AsynchronousOperation;

typedef void (^AsynchronousOperationBlock)(AsynchronousOperation* operation);

@interface AsynchronousOperation : NSOperation

@property (weak, nonatomic) NSOperationQueue* queue;

- (id)initWithBlock:(AsynchronousOperationBlock)block;

- (id)initWithQueue:(NSOperationQueue*)queue block:(AsynchronousOperationBlock)block;

- (void)finish;

- (void)finish:(void (^)(void))completionQueueBlock;

@end

@interface NSOperationQueue (PGAsynchronousOperation)

+ (instancetype)queueNamed:(NSString*)name;

+ (instancetype)queueNamed:(NSString*)name count:(NSUInteger)count;

- (AsynchronousOperation*)addAsynchronousOperation:(NSString*)name block:(AsynchronousOperationBlock)block;

- (AsynchronousOperation*)addAsynchronousOperationWithBlock:(AsynchronousOperationBlock)block;

- (BOOL)containsOperationNamed:(NSString*)name;

@end

static inline AsynchronousOperation* runAsynchronousOperation (NSString *queue, NSUInteger count, AsynchronousOperationBlock block) {
    return [[NSOperationQueue queueNamed:queue count:count] addAsynchronousOperationWithBlock:block];
};

static inline NSArray* runAsynchronousOperations (NSString *queue, NSUInteger count, AsynchronousOperationBlock block, ...) {
    va_list args;
    va_start(args, block);
    NSMutableArray* operations = [NSMutableArray array];
    for (; block != nil; block = va_arg(args, id)) {
        [operations addObject:runAsynchronousOperation(queue, count, block)];
    }
    va_end(args);
    return [operations copy];
};

static inline AsynchronousOperation* runDefaultAsynchronousOperation (NSString *queue, AsynchronousOperationBlock block) {
    return runAsynchronousOperation(queue, NSOperationQueueDefaultMaxConcurrentOperationCount, block);
};

static inline NSArray* runDefaultAsynchronousOperations (NSString *queue, AsynchronousOperationBlock block, ...) {
    va_list args;
    va_start(args, block);
    NSMutableArray* operations = [NSMutableArray array];
    for (; block != nil; block = va_arg(args, id)) {
        [operations addObject:runDefaultAsynchronousOperation(queue, block)];
    }
    va_end(args);
    return [operations copy];
};

static inline AsynchronousOperation* runUnaryAsynchronousOperation (NSString *queue, AsynchronousOperationBlock block) {
    return runAsynchronousOperation(queue, 1, block);
};

static inline NSArray* runUnaryAsynchronousOperations (NSString *queue, AsynchronousOperationBlock block, ...) {
    va_list args;
    va_start(args, block);
    NSMutableArray* operations = [NSMutableArray array];
    for (; block != nil; block = va_arg(args, id)) {
        [operations addObject:runUnaryAsynchronousOperation(queue, block)];
    }
    va_end(args);
    return [operations copy];
};
