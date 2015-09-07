//
//  WLUploadingQueue.h
//  meWrap
//
//  Created by Ravenpod on 3/3/15.
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

+ (instancetype)queueForEntriesOfClass:(Class)entryClass;

+ (void)upload:(WLUploading*)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

+ (void)start;

- (void)prepareAndStart;

- (void)prepare;

- (void)start;

- (void)upload:(WLUploading*)uploading success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)addDependentQueue:(WLUploadingQueue*)queue;

@end
