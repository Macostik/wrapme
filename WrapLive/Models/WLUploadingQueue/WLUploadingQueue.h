//
//  WLUploadingQueue.h
//  WrapLive
//
//  Created by Sergey Maximenko on 14.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAPIManager.h"

@class WLWrap;
@class WLCandy;
@class WLUploadingItem;

@interface WLUploadingQueue : NSObject

+ (instancetype)instance;

- (void)addItem:(WLUploadingItem*)item;

- (WLUploadingItem*)addItemWithCandy:(WLCandy*)candy wrap:(WLWrap*)wrap;

- (void)removeItem:(WLUploadingItem*)item;

- (void)addCandiesToWrapIfNeeded:(WLWrap*)wrap;

- (void)uploadImage:(UIImage*)image wrap:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

- (void)uploadMessage:(NSString*)message wrap:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

@end

@interface WLUploadingItem : NSObject

@property (weak, nonatomic) WLWrap* wrap;

@property (weak, nonatomic) WLCandy* candy;

@property (weak, nonatomic) AFURLConnectionOperation* operation;

@property (nonatomic) float progress;

@property (strong, nonatomic) void (^progressChangeBlock) (float progress);

@end
