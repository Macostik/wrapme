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

- (id)initWithBlock:(void (^)(AsynchronousOperation* operation))block;
- (id)initWithQueue:(NSOperationQueue*)queue block:(void (^)(AsynchronousOperation* operation))block;

- (void)finish;
- (void)finish:(void (^)(void))completionQueueBlock;

@end

@interface NSOperationQueue (PGAsynchronousOperation)

+ (instancetype)queueWithIdentifier:(NSString*)identifier;

+ (instancetype)queueWithIdentifier:(NSString*)identifier count:(NSUInteger)count;

- (AsynchronousOperation*)addAsynchronousOperation:(NSString*)name block:(void (^)(AsynchronousOperation* operation))block;

- (AsynchronousOperation*)addAsynchronousOperationWithBlock:(void (^)(AsynchronousOperation* operation))block;

- (BOOL)containsOperationNamed:(NSString*)name;

@end
