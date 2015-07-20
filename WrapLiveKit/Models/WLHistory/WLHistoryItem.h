//
//  WLHistoryItem.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"

@class WLHistory;

@interface WLHistoryItem : WLPaginatedSet <WLPaginationEntry>

@property (weak, nonatomic) WLHistory *history;

@property (strong, nonatomic) NSDate* date;

@property (nonatomic) CGPoint offset;

@property (strong, nonatomic) WLPaginatedRequest* request;

@end
