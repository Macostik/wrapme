//
//  WLGroupedSet.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"
#import "WLHistoryItem.h"

@class WLCandy;
@class WLWrap;

@interface WLHistory : WLPaginatedSet

+ (instancetype)historyWithWrap:(WLWrap*)wrap;

- (void)clear;

- (WLHistoryItem*)itemWithCandy:(WLCandy*)candy;

- (WLHistoryItem*)itemForDate:(NSDate*)date;

- (WLHistoryItem*)itemForDate:(NSDate*)date create:(BOOL)create;

@end

