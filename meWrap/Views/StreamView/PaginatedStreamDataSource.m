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
#import "WLNetwork.h"

@interface PaginatedStreamDataSource () <WLSetDelegate, WLNetworkReceiver>

@property (weak, nonatomic) WLStreamLoadingView *loadingView;

@property (nonatomic) BOOL animateLoading;

@end

@implementation PaginatedStreamDataSource

@dynamic items;

- (void)didAwake {
    [super didAwake];
    
    __weak typeof(self)weakSelf = self;
    self.loadingMetrics = [self addFooterMetrics:[[WLStreamLoadingView streamLoadingMetrics] change:^(StreamMetrics *metrics) {
        [metrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
            if (weakSelf.streamView.horizontal) {
                return weakSelf.streamView.fittingContentWidth;
            } else {
                return weakSelf.streamView.fittingContentHeight;
            }
        }];
        [metrics setHiddenAt:^BOOL(StreamPosition *position, StreamMetrics *metrics) {
            return weakSelf.items.count > 0 || weakSelf.items.completed;
        }];
        [metrics setFinalizeAppearing:^(StreamItem *item, id entry) {
            WLStreamLoadingView *loadingView = (id)item.view;
            loadingView.animating = weakSelf.animateLoading;
            weakSelf.loadingView = loadingView;
        }];
    }]];
}

- (void)setAnimateLoading:(BOOL)animateLoading {
    _animateLoading = animateLoading;
    if (self.loadingView) {
        self.loadingView.animating = animateLoading;
    }
}

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
    return self.items && !self.items.completed;
}

- (void)append:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [self.items older:success failure:failure];
}

// MARK: - WLPaginatedSetDelegate

- (void)appendItemsIfNeededWithTargetContentOffset:(CGPoint)targetContentOffset {
    StreamView *streamView = self.streamView;
    BOOL reachedRequiredOffset = NO;
    if (self.streamView.horizontal) {
        reachedRequiredOffset = (streamView.maximumContentOffset.x - targetContentOffset.x) < streamView.fittingContentWidth;
    } else {
        reachedRequiredOffset = (streamView.maximumContentOffset.y - targetContentOffset.y) < streamView.fittingContentHeight;
    }
    if (reachedRequiredOffset && [self appendable]) {
        if ([WLNetwork network].reachable) {
            self.animateLoading = YES;
            __weak typeof(self)weakSelf = self;
            [self append:nil failure:^(NSError *error) {
                weakSelf.animateLoading = NO;
                [error showIgnoringNetworkError];
            }];
        } else {
            [[WLNetwork network] addReceiver:self];
            self.animateLoading = NO;
        }
    }
}

- (void)setDidChange:(WLPaginatedSet *)group {
    [self reload];
}

- (void)streamViewDidLayout:(StreamView *)streamView {
    [super streamViewDidLayout:streamView];
    run_after_asap(^{
        [self appendItemsIfNeededWithTargetContentOffset:streamView.contentOffset];
    });
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self appendItemsIfNeededWithTargetContentOffset:*targetContentOffset];
}

// MARK: - WLNetworkReceiver

- (void)networkDidChangeReachability:(WLNetwork *)network {
    if (network.reachable) {
        [network removeReceiver:self];
        [self appendItemsIfNeededWithTargetContentOffset:self.streamView.contentOffset];
    }
}

@end
