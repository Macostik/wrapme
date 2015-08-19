//
//  WLHomeViewSection.m
//  moji
//
//  Created by Ravenpod on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHomeDataSource.h"
#import "WLWrapCell.h"
#import "WLOperationQueue.h"
#import "UIView+Shorthand.h"
#import "WLEntryCell.h"
#import "WLLoadingView.h"

@interface WLHomeDataSource ()

@end

@implementation WLHomeDataSource

- (void)setItems:(id<WLBaseOrderedCollection>)items {
    if (items.count > 0) self.wrap = [items objectAtIndex:0];
    [super setItems:items];
}

- (void)setWrap:(WLWrap *)wrap {
    if (_wrap != wrap) {
        _wrap = wrap;
        if (wrap) [self fetchTopWrapIfNeeded:wrap];
    }
}

- (void)fetchTopWrapIfNeeded:(WLWrap*)wrap {
    if ([wrap.candies count] < WLHomeTopWrapCandiesLimit) {
        runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
            if (!wrap.valid) {
                [operation finish];
                return;
            }
            [wrap fetch:WLWrapContentTypeRecent success:^(NSSet* set) {
                [operation finish];
            } failure:^(NSError *error) {
                [operation finish];
            }];
        });
    }
}

- (NSInteger)streamView:(StreamView *)streamView numberOfItemsInSection:(NSInteger)section {
    self.wrap = [self.items tryAt:0];
    return [super streamView:streamView numberOfItemsInSection:section];
}

@end
