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

@property (strong, nonatomic) NSTimer* timer;

@end

@implementation AsynchronousOperation
{
	BOOL executing;
	BOOL finished;
}

- (void)setTimer:(NSTimer *)timer {
    if (_timer) {
        [_timer invalidate];
    }
    _timer = timer;
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
		__weak typeof(self)weakSelf = self;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            weakSelf.timer = [NSTimer scheduledTimerWithTimeInterval:45 target:self selector:@selector(finish) userInfo:nil repeats:NO];
            weakSelf.operationBlock(weakSelf);
            weakSelf.operationBlock = nil;
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
    [self.timer invalidate];
    
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

+ (instancetype)queueNamed:(NSString*)name count:(NSUInteger)count {
    static NSMutableDictionary *queues = nil;
    if (!queues) queues = [NSMutableDictionary dictionary];
    NSOperationQueue *queue = [queues objectForKey:name];
    if (!queue) {
        queue = queues[name] = [[NSOperationQueue alloc] init];
        queue.name = name;
    }
    queue.maxConcurrentOperationCount = count;
    return queue;
}

+ (instancetype)queueNamed:(NSString *)name {
    return [self queueNamed:name count:NSOperationQueueDefaultMaxConcurrentOperationCount];
}

- (AsynchronousOperation *)addAsynchronousOperationWithBlock:(AsynchronousOperationBlock)block {
    AsynchronousOperation* operation = [[AsynchronousOperation alloc] initWithQueue:self block:block];
    [self addOperation:operation];
    return operation;
}

@end
