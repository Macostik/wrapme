//
//  WLGroupedSet.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLPaginatedSet.h"
#import "WLCandiesRequest.h"

@class WLCandy;
@class WLGroup;

@interface WLGroupedSet : WLPaginatedSet

@property (nonatomic) NSInteger type;

- (void)clear;

- (WLGroup*)groupWithCandy:(WLCandy*)candy;

- (WLGroup*)groupForDate:(NSDate*)date;

- (WLGroup*)groupForDate:(NSDate*)date create:(BOOL)create;

@end

@interface WLGroup : WLPaginatedSet

@property (strong, nonatomic) NSDate* date;

@property (nonatomic) CGPoint offset;

@property (strong, nonatomic) WLCandiesRequest* request;

+ (instancetype)group;

@end


