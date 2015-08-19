//
//  PaginatedStreamDataSource.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "PaginatedStreamDataSource.h"
#import "WLStreamLoadingView.h"
#import "UIScrollView+Additions.h"
#import "StreamLayout.h"

@interface PaginatedStreamDataSource () <WLPaginatedSetDelegate>

@property (weak, nonatomic) WLStreamLoadingView *loadingView;

@end

@implementation PaginatedStreamDataSource

@dynamic items;

- (void)setItems:(WLPaginatedSet *)items {
    [super setItems:items];
    items.delegate = self;
}

- (void)refresh {
    [self refresh:nil failure:nil];
}

- (void)refresh:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [self.items newer:success failure:failure];
}

- (BOOL)appendable {
    if (self.appendableBlock && !self.appendableBlock(self)) {
        return NO;
    }
    return !self.items.completed;
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
            return index.item != ([weakSelf.items count] - 1) || ![weakSelf appendable];
        }];
        [metrics setViewAfterSetupBlock:^(StreamItem *item, WLStreamLoadingView *view, id entry) {
            weakSelf.loadingView = view;
            view.error = NO;
            [weakSelf append:nil failure:^(NSError *error) {
                [error showIgnoringNetworkError];
                if (error) view.error = YES;
            }];
        }];
    }];
}

// MARK: - WLPaginatedSetDelegate

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self reload];
}

- (void)paginatedSetCompleted:(WLPaginatedSet *)group {
    if (self.headerAnimated && self.streamView.scrollable) {
        StreamLayout *layout = self.streamView.layout;
        CGPoint offset = layout.horizontal ?
        CGPointMake(self.streamView.contentOffset.x - WLStreamLoadingViewDefaultSize, 0) :
        CGPointMake(0, self.streamView.contentOffset.y - WLStreamLoadingViewDefaultSize);
        [self.streamView trySetContentOffset:offset animated:YES];
        self.loadingView.animating = NO;
        run_after(0.5, ^{
            [self reload];
        });
    } else {
        [self paginatedSetChanged:group];
    }
}

@end
