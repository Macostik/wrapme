//
//  WLHistoryItem.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHistoryItem.h"

@implementation WLHistoryItem

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sortComparator = comparatorByCreatedAt;
        self.offset = CGPointZero;
        self.request = [WLCandiesRequest request];
        self.request.sameDay = YES;
    }
    return self;
}

- (void)configureRequest:(WLCandiesRequest *)request {
    WLWrap* wrap = [[self.entries firstObject] wrap];
    if (wrap) {
        request.wrap = wrap;
    }
    [super configureRequest:request];
}

- (NSDate *)paginationDate {
    return self.date;
}

@end
