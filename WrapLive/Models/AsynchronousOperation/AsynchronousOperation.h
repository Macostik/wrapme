//
//  PGPublishOperation.h
//  Pressgram
//
//  Created by Sergey Maximenko on 10.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AsynchronousOperation : NSOperation

@property (weak, nonatomic) NSOperationQueue* queue;

@property (strong, nonatomic) NSString *identifier;

- (id)initWithBlock:(void (^)(AsynchronousOperation* operation))block;
- (id)initWithQueue:(NSOperationQueue*)queue block:(void (^)(AsynchronousOperation* operation))block;

- (void)finish;
- (void)finish:(void (^)(void))completionQueueBlock;

@end

@interface NSOperationQueue (PGAsynchronousOperation)

+ (instancetype)queueWithIdentifier:(NSString*)identifier;

+ (instancetype)queueWithIdentifier:(NSString*)identifier count:(NSUInteger)count;

+ (AsynchronousOperation*)addAsynchronousOperationToQueueWithIdentifier:(NSString*)queueIdentifier operationIdentifier:(NSString*)operationIdentifier block:(void (^)(AsynchronousOperation* operation))block;

+ (AsynchronousOperation*)addAsynchronousOperationToQueueWithIdentifier:(NSString*)queueIdentifier block:(void (^)(AsynchronousOperation* operation))block;

- (AsynchronousOperation*)addAsynchronousOperation:(NSString*)identifier block:(void (^)(AsynchronousOperation* operation))block;

- (AsynchronousOperation*)addAsynchronousOperationWithBlock:(void (^)(AsynchronousOperation* operation))block;

- (BOOL)containsAsynchronousOperation:(NSString*)identifier;

@end
