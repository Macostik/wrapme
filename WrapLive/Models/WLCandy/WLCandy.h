//
//  WLCandy.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEntry.h"

@class WLComment;

@protocol WLComment @end

static NSInteger WLCandyTypeImage = 10;
static NSInteger WLCandyTypeConversation = 20;

@interface WLCandy : WLWrapEntry

@property (strong, nonatomic) NSArray<WLComment>* comments;
@property (nonatomic) NSInteger type;

- (void)addComment:(WLComment*)comment;

- (WLComment*)addCommentWithText:(NSString*)text;

@end
