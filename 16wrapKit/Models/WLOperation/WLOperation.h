//
//  WLOperation.h
//  moji
//
//  Created by Ravenpod on 3/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLOperation, WLOperationQueue;

typedef void (^WLOperationBlock)(WLOperation *operation);

@interface WLOperation : NSObject

@property (weak, nonatomic) WLOperationQueue *queue;

@property (strong, nonatomic) WLOperationBlock block;

@property (nonatomic) BOOL executing;

@property (nonatomic) BOOL finished;

+ (instancetype)operationWithBlock:(WLOperationBlock)block;

- (instancetype)initWithBlock:(WLOperationBlock)block;

- (void)start;

- (void)cancel;

- (void)finish;

- (void)finish:(void (^) (void))queueCompletion;

@end
