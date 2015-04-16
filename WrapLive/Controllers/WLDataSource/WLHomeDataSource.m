//
//  WLHomeViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHomeDataSource.h"
#import "WLWrapCell.h"
#import "WLOperationQueue.h"
#import "UIView+Shorthand.h"
#import "WLWrapRequest.h"
#import "WLEntryCell.h"

@interface WLHomeDataSource ()

@end

@implementation WLHomeDataSource

- (void)awakeAfterInit {
    [super awakeAfterInit];
    self.minimumLineSpacing = self.sectionLeftInset = self.sectionRightInset = WLConstants.pixelSize;
}

- (void)setItems:(id<WLDataSourceItems>)items {
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
            [wrap fetch:WLWrapContentTypeRecent success:^(NSOrderedSet* candies) {
                [operation finish];
            } failure:^(NSError *error) {
                [operation finish];
            }];
        });
    }
}

@end
