//
//  PGPublishOperation.m
//  Pressgram
//
//  Created by Sergey Maximenko on 10.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import "AsynchronousOperation.h"

@interface AsynchronousOperation ()

@property (copy, nonatomic) void (^operationBlock) (AsynchronousOperation *operation);

@end

@implementation AsynchronousOperation
{
	BOOL executing;
	BOOL finished;
}

- (id)initWithQueue:(NSOperationQueue *)queue block:(void (^)(AsynchronousOperation *))block {
	self = [self initWithBlock:block];
	if (self == nil)
		return nil;
	
	self.queue = queue;
	
	return self;
}

- (id)initWithBlock:(void (^)(AsynchronousOperation *operation))block {
	self = [super init];
	if (self == nil)
		return nil;
	
	self.operationBlock = block;
	executing = NO;
	finished = NO;
	
	return self;
}

- (void)start {
	if ([self isCancelled]) {
		// Must move the operation to the finished state if it is canceled.
		[self willChangeValueForKey:@"isFinished"];
		finished = YES;
		[self didChangeValueForKey:@"isFinished"];
		return;
	}
	
	[self willChangeValueForKey:@"isExecuting"];
	executing = YES;
	[self didChangeValueForKey:@"isExecuting"];
    
	if (self.operationBlock) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finish) object:nil];
        [self performSelector:@selector(finish) withObject:nil afterDelay:45];
		__weak typeof(self)weakSelf = self;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            weakSelf.operationBlock(weakSelf);
        }];
	} else {
		[self finish];
	}
}

- (BOOL)isExecuting {
	return executing;
}

- (BOOL)isFinished {
	return finished;
}

- (void)finish {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finish) object:nil];
    
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	
	executing = NO;
	finished = YES;
	
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}

- (void)finish:(void (^)(void))completionQueueBlock {
	[self finish];
	
	if (self.queue.operationCount == 0 && completionQueueBlock) {
		completionQueueBlock();
	}
}

- (BOOL)isConcurrent {
	return YES;
}

@end

@implementation NSOperationQueue (PGAsynchronousOperation)

+ (instancetype)queueWithIdentifier:(NSString*)identifier count:(NSUInteger)count {
    static NSMutableDictionary *queues = nil;
    if (!queues) queues = [NSMutableDictionary dictionary];
    NSOperationQueue *queue = [queues objectForKey:identifier];
    if (!queue) {
        queue = queues[identifier] = [[NSOperationQueue alloc] init];
        queue.name = identifier;
    }
    queue.maxConcurrentOperationCount = count;
    return queue;
}

+ (instancetype)queueWithIdentifier:(NSString *)identifier {
    return [self queueWithIdentifier:identifier count:NSOperationQueueDefaultMaxConcurrentOperationCount];
}

- (AsynchronousOperation *)addAsynchronousOperation:(NSString *)identifier block:(void (^)(AsynchronousOperation *))block {
    AsynchronousOperation* operation = [[AsynchronousOperation alloc] initWithQueue:self block:block];
    operation.name = identifier;
    [self addOperation:operation];
    return operation;
}

- (AsynchronousOperation*)addAsynchronousOperationWithBlock:(void (^)(AsynchronousOperation *operation))block {
	return [self addAsynchronousOperation:nil block:block];
}

- (BOOL)containsOperationNamed:(NSString *)name {
    for (AsynchronousOperation* operation in self.operations) {
        if ([[operation name] isEqualToString:name]) {
            return YES;
        }
    }
    return NO;
}

@end
