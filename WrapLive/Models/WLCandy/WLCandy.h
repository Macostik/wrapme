//
//  WLCandy.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@class WLComment;

@protocol WLComment @end

@interface WLCandy : WLEntry

@property (strong, nonatomic) NSArray<WLComment>* comments;
@property (strong, nonatomic) NSString* cover;

- (void)addComment:(WLComment*)comment;

@end
