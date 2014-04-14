//
//  WLCandy.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEntry.h"

@class WLComment;
@class WLUploadingItem;

@protocol WLComment @end

static NSInteger WLCandyTypeImage = 10;
static NSInteger WLCandyTypeChatMessage = 20;

@interface WLCandy : WLWrapEntry

@property (strong, nonatomic) NSArray<WLComment>* comments;

@property (nonatomic) NSInteger type;

@property (strong, nonatomic) NSString * chatMessage;

@property (weak, nonatomic) WLUploadingItem* uploadingItem;

+ (instancetype)chatMessageWithText:(NSString*)text;

+ (instancetype)imageWithFileAtPath:(NSString*)path;

- (void)addComment:(WLComment*)comment;

- (WLComment*)addCommentWithText:(NSString*)text;

- (BOOL)isImage;

- (BOOL)isChatMessage;

- (BOOL)isEqualToCandy:(WLCandy *)candy;

@end
