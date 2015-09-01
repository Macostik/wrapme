//
//  WLGroupedSet.h
//  moji
//
//  Created by Ravenpod on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"
#import "WLHistoryItem.h"

@class WLCandy;
@class WLWrap;

@interface WLHistory : WLPaginatedSet

@property (nonatomic) BOOL checkCompletion;

+ (instancetype)historyWithWrap:(WLWrap*)wrap;

+ (instancetype)historyWithWrap:(WLWrap *)wrap checkCompletion:(BOOL)checkCompletion;

- (void)clear;

- (WLHistoryItem*)itemWithCandy:(WLCandy*)candy;

- (WLHistoryItem*)itemForDate:(NSDate*)date;

- (WLHistoryItem*)itemForDate:(NSDate*)date create:(BOOL)create;

@end

