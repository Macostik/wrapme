//
//  PaginatedStreamViewDataSource.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "PaginatedStreamViewDataSource.h"
#import "WLStreamLoadingView.h"

@implementation PaginatedStreamViewDataSource

@dynamic items;

- (void)refresh {
    [self refresh:nil failure:nil];
}

- (BOOL)appendable {
    if (self.appendableBlock && !self.appendableBlock(self)) {
        return NO;
    }
    return !self.items.completed;
}

- (void)refresh:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [self.items newer:success failure:failure];
}

- (void)append:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [self.items older:success failure:failure];
}

- (void)setMetrics:(StreamMetrics *)metrics {
    [super setMetrics:metrics];
    __weak typeof(self)weakSelf = self;
    [metrics addFooter:^(StreamMetrics *metrics) {
        metrics.identifier = @"WLStreamLoadingView";
        metrics.size.value = 60;
        [metrics.hidden setBlock:^BOOL(StreamIndex *index) {
            return index.item == ([weakSelf.items count] - 1) && ![weakSelf appendable];
        }];
        [metrics setViewAfterSetupBlock:^(StreamItem *item, WLStreamLoadingView *view, id entry) {
            view.error = NO;
            [weakSelf append:nil failure:^(NSError *error) {
                [error showIgnoringNetworkError];
                if (error) view.error = YES;
            }];
        }];
    }];
}

@end
