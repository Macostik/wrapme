//
//  WLUploadingQueue.h
//  meWrap
//
//  Created by Ravenpod on 3/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBroadcaster.h"
#import "DefinedBlocks.h"

@class WLUploadingQueue, Uploading;

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

@property (strong, nonatomic) NSString* entityName;

+ (instancetype)queueForEntityName:(NSString*)entityName;

+ (void)upload:(Uploading *)uploading success:(ObjectBlock)success failure:(FailureBlock)failure;

+ (void)start;

- (void)prepareAndStart;

- (void)prepare;

- (void)start;

- (void)upload:(Uploading *)uploading success:(ObjectBlock)success failure:(FailureBlock)failure;

- (void)addDependentQueue:(WLUploadingQueue*)queue;

@end
