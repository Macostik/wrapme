//
//  WLUploadingQueue.h
//  WrapLive
//
//  Created by Sergey Maximenko on 14.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAPIManager.h"
#import "WLArchivingObject.h"

@class WLWrap;
@class WLCandy;
@class WLUploadingItem;

@interface WLUploadingQueue : NSObject

+ (instancetype)instance;

- (void)addItem:(WLUploadingItem*)item;

- (WLUploadingItem*)addItemWithCandy:(WLCandy*)candy wrap:(WLWrap*)wrap;

- (void)removeItem:(WLUploadingItem*)item;

- (void)updateWrap:(WLWrap*)wrap;

- (void)uploadImage:(UIImage*)image wrap:(WLWrap*)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)uploadMessage:(NSString*)message wrap:(WLWrap*)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLUploadingItem : WLArchivingObject

@property (strong, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) WLCandy* candy;

@property (nonatomic) float progress;

@property (strong, nonatomic) void (^progressChangeBlock) (float progress);

- (void)setOperation:(AFURLConnectionOperation *)operation;

- (AFURLConnectionOperation *)operation;

- (void)upload:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
