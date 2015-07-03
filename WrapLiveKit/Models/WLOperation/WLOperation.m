//
//  WLOperation.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLOperation.h"
#import "WLOperationQueue.h"
#import "NSString+Additions.h"

@interface WLOperation ()

@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSString *identifier;

@end

@implementation WLOperation

+ (instancetype)operationWithBlock:(WLOperationBlock)block {
    return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(WLOperationBlock)block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

- (void)start {
    if (self.block) {
        self.executing = YES;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:45 target:self selector:@selector(timeout:) userInfo:nil repeats:NO];
        self.block(self);
        self.block = nil;
#ifdef DEBUG
        self.identifier = GUID();
        NSLog(@"WLOperation started: %@ queue: %@", self.identifier, self.queue.name);
#endif
    } else {
        [self finish];
    }
}

- (void)cancel {
    if (!self.executing) {
        [self finish];
    }
}

- (void)setTimer:(NSTimer *)timer {
    if (_timer) {
        [_timer invalidate];
    }
    _timer = timer;
}

- (void)timeout:(NSTimer*)timer {
#ifdef DEBUG
    NSLog(@"WLOperation timeout: %@ queue: %@", self.identifier, self.queue.name);
#endif
    [self finish];
}

- (void)finish {
#ifdef DEBUG
    NSLog(@"WLOperation finished: %@ queue: %@", self.identifier, self.queue.name);
#endif
    self.timer = nil;
    self.executing = NO;
    self.finished = YES;
    self.block = nil;
    [self.queue finishOperation:self];
}

- (void)finish:(void (^)(void))queueCompletion {
    [self finish];
    if (queueCompletion && self.queue && self.queue.operations.count == 0) {
        queueCompletion();
    }
}

@end
