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
		self.operationBlock(self);
	}
	else {
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

- (AsynchronousOperation*)addAsynchronousOperationWithBlock:(void (^)(AsynchronousOperation *operation))block {
	AsynchronousOperation* operation = [[AsynchronousOperation alloc] initWithQueue:self block:block];
	[self addOperation:operation];
	return operation;
}

@end
