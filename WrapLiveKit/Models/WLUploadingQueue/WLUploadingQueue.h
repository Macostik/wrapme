//
//  WLUploadingQueue.h
//  WrapLive
//
//  Created by Sergey Maximenko on 3/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLUploadingQueue;
@class WLUploading;

@protocol WLUploadingQueueReceiver <WLBroadcastReceiver>

@optional
- (void)uploadingQueueDidStart:(WLUploadingQueue*)queue;

- (void)uploadingQueueDidStop:(WLUploadingQueue*)queue;

- (void)uploadingQueueDidChange:(WLUploadingQueue*)queue;

@end

@interface WLUploadingQueue : WLBroadcaster

@property (nonatomic) BOOL isUploading;

@property (readonly, nonatomic) BOOL isEmpty;

@property (readonly, nonatomic) NSUInteger count;

@property (strong, nonatomic) Class entryClass;

+ (NSArray*)allQueues;

+ (instancetype)queueForEntriesOfClass:(Class)entryClass;

+ (void)upload:(WLUploading*)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

+ (void)start;

+ (void)start:(WLBlock)completion;

- (void)prepareAndStart;

- (void)prepare;

- (void)start;

- (void)start:(WLBlock)completion;

- (void)upload:(WLUploading*)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
