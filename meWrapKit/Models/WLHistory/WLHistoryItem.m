//
//  WLHistoryItem.m
//  meWrap
//
//  Created by Ravenpod on 12/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHistoryItem.h"
#import "WLPaginatedRequest+Defined.h"

@implementation WLHistoryItem

@dynamic request;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sortComparator = comparatorByCreatedAt;
        self.offset = CGPointZero;
        self.request = [WLPaginatedRequest candies:nil];
        self.request.sameDay = YES;
    }
    return self;
}

- (void)configureRequest:(WLPaginatedRequest *)request {
    WLWrap* wrap = [[self.entries firstObject] wrap];
    [super configureRequest:[request candies:wrap]];
}

- (NSDate *)paginationDate {
    return self.date;
}

@end
