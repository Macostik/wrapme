//
//  WLCandy.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEntry.h"

@class WLComment;
@class WLUploading;
@class WLWrap;

@protocol WLComment @end

static NSInteger WLCandyTypeImage = 10;
static NSInteger WLCandyTypeChatMessage = 20;

@interface WLCandy : WLWrapEntry

@property (strong, nonatomic) NSArray<WLComment>* comments;

@property (nonatomic) NSInteger type;

@property (strong, nonatomic) NSString *chatMessage;

@property (weak, nonatomic) WLUploading* uploading;

@property (strong, nonatomic) NSString *uploadIdentifier;

@property (strong, nonatomic) NSString* wrapIdentifier;

+ (instancetype)candyWithType:(NSInteger)type;

+ (instancetype)chatMessageWithText:(NSString*)text;

+ (instancetype)imageWithPicture:(WLPicture*)picture;

+ (instancetype)imageWithFileAtPath:(NSString*)path;

- (void)addComment:(WLComment*)comment;

- (void)removeComment:(WLComment*)comment;

- (WLComment*)addCommentWithText:(NSString*)text;

- (BOOL)isImage;

- (BOOL)isChatMessage;

- (BOOL)belongsToWrap:(WLWrap*)wrap;

- (instancetype)updateWithDictionary:(NSDictionary *)dict broadcast:(BOOL)broadcast;

@end
