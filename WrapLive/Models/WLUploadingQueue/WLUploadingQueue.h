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
@class WLUploading;

@interface WLUploadingQueue : NSObject

+ (instancetype)instance;

- (void)addUploading:(WLUploading*)uploading;

- (WLUploading*)addUploadingWithCandy:(WLCandy*)candy wrap:(WLWrap*)wrap;

- (void)removeUploading:(WLUploading*)uploading;

- (void)updateWrap:(WLWrap*)wrap;

- (void)reviseCandy:(WLCandy*)candy;

- (void)uploadImage:(UIImage*)image wrap:(WLWrap*)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)uploadMessage:(NSString*)message wrap:(WLWrap*)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLUploading : WLArchivingObject

@property (strong, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) WLCandy* candy;

- (void)setOperation:(AFURLConnectionOperation *)operation;

- (AFURLConnectionOperation *)operation;

- (void)upload:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
