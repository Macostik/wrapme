//
//  WLCandy.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandy.h"
#import "WLBlocks.h"

typedef NS_ENUM(NSUInteger, WLCandyType) {
	WLCandyTypeImage = 10,
	WLCandyTypeMessage = 20
};

@interface WLCandy (Extended)

+ (instancetype)candyWithType:(WLCandyType)type wrap:(WLWrap*)wrap;

- (BOOL)isCandyOfType:(WLCandyType)type;

- (BOOL)isImage;

- (BOOL)isMessage;

- (BOOL)belongsToWrap:(WLWrap *)wrap;

- (void)addComment:(WLComment *)comment;

- (void)removeComment:(WLComment *)comment;

- (void)uploadComment:(NSString *)text success:(WLCommentBlock)success failure:(WLFailureBlock)failure;

@end
