//
//  WLGroupedSet.h
//  meWrap
//
//  Created by Ravenpod on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"
#import "WLHistoryItem.h"

@interface WLHistory : WLPaginatedSet

+ (instancetype)historyWithWrap:(Wrap *)wrap;

+ (instancetype)historyWithWrap:(Wrap *)wrap checkCompletion:(BOOL)checkCompletion;

- (void)clear;

- (WLHistoryItem*)itemWithCandy:(Candy *)candy;

@end

