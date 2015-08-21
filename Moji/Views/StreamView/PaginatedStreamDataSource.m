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

@property (weak, nonatomic) StreamMetrics *loaderMetrics;

@end

@implementation PaginatedStreamDataSource

@dynamic items;

- (void)didAwake {
    [super didAwake];
    
    __weak typeof(self)weakSelf = self;
    self.loaderMetrics = [self addFooterMetrics:[StreamMetrics metrics:^(StreamMetrics *metrics) {
        metrics.identifier = @"WLStreamLoadingView";
        metrics.size = WLStreamLoadingViewDefaultSize;
        [metrics setHiddenBlock:^BOOL(StreamIndex *index) {
            return ![weakSelf appendable];
        }];
        [metrics setViewWillAppearBlock:^(StreamItem *item, WLStreamLoadingView *view, id entry) {
            weakSelf.loadingView = view;
            view.error = NO;
            [weakSelf append:nil failure:^(NSError *error) {
                [error showIgnoringNetworkError];
                if (error) view.error = YES;
            }];
        }];
    }]];
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
    return !self.items.completed;
}

- (void)append:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [self.items older:success failure:failure];
}

// MARK: - WLPaginatedSetDelegate

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self reload];
}

- (void)paginatedSetCompleted:(WLPaginatedSet *)group {
    StreamLayout *layout = self.streamView.layout;
    CGPoint offset = layout.horizontal ?
    CGPointMake(self.streamView.contentOffset.x - self.loaderMetrics.size, 0) :
    CGPointMake(0, self.streamView.contentOffset.y - self.loaderMetrics.size);
    [self.streamView trySetContentOffset:offset animated:YES];
    self.loadingView.animating = NO;
    run_after(0.5, ^{
        [self reload];
    });
}

@end
