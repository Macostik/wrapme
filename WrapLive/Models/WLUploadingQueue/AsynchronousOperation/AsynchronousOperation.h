//
//  PGPublishOperation.h
//  Pressgram
//
//  Created by Sergey Maximenko on 10.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AsynchronousOperation : NSOperation

- (id)initWithBlock:(void (^)(AsynchronousOperation* operation))block;
- (id)initWithQueue:(NSOperationQueue*)queue block:(void (^)(AsynchronousOperation* operation))block;

@property (weak, nonatomic) NSOperationQueue* queue;

- (void)finish;
- (void)finish:(void (^)(void))completionQueueBlock;

@end

@interface NSOperationQueue (PGAsynchronousOperation)

- (AsynchronousOperation*)addAsynchronousOperationWithBlock:(void (^)(AsynchronousOperation* operation))block;

@end
