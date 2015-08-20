//
//  StreamViewDataSource.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamDataSource.h"
#import "WLLayoutPrioritizer.h"

@interface StreamDataSource ()

@property (strong, nonatomic) IBOutlet WLLayoutPrioritizer *scrollDirectionLayoutPrioritizer;

@end

@implementation StreamDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        [self didAwake];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        [self didAwake];
    }
    return self;
}

- (void)didAwake {
    
}

- (StreamMetrics*)addHeaderMetrics:(StreamMetrics*)metrics {
    if (!self.headerMetrics) self.headerMetrics = [NSMutableArray array];
    [self.headerMetrics addObject:metrics];
    return metrics;
}

- (StreamMetrics*)addMetrics:(StreamMetrics*)metrics {
    if (!self.metrics) self.metrics = [NSMutableArray array];
    [self.metrics addObject:metrics];
    return metrics;
}

- (StreamMetrics*)addFooterMetrics:(StreamMetrics*)metrics {
    if (!self.footerMetrics) self.footerMetrics = [NSMutableArray array];
    [self.footerMetrics addObject:metrics];
    return metrics;
}

- (void)setItems:(id<WLBaseOrderedCollection>)items {
    _items = items;
    [self reload];
}

- (void)reload {
    if (self.streamView.delegate == self) {
        [self.streamView reload];
    }
}

- (void)setItemIdentifier:(NSString *)itemIdentifier {
    if (!self.metrics.nonempty) [self addMetrics:[[StreamMetrics alloc] init]];
    StreamMetrics *metrics = [self.metrics firstObject];
    metrics.identifier = itemIdentifier;
}

- (NSString *)itemIdentifier {
    StreamMetrics *metrics = [self.metrics firstObject];
    return metrics.identifier;
}

- (void)setItemSize:(CGFloat)itemSize {
    if (!self.metrics.nonempty) [self addMetrics:[[StreamMetrics alloc] init]];
    StreamMetrics *metrics = [self.metrics firstObject];
    metrics.size.value = itemSize;
}

- (CGFloat)itemSize {
    StreamMetrics *metrics = [self.metrics firstObject];
    return metrics.size.value;
}

- (void)refresh:(WLRefresher*)sender {
    [self refresh:^(id object) {
        [sender setRefreshing:NO animated:YES];
    } failure:^(NSError *error) {
        [sender setRefreshing:NO animated:YES];
    }];
}

- (void)refresh {
    [self refresh:nil failure:nil];
}

- (void)refresh:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (success) success(nil);
}

- (void)setRefreshable {
    [self setRefreshableWithStyle:WLRefresherStyleWhite];
}

- (void)setRefreshableWithStyle:(WLRefresherStyle)style contentMode:(UIViewContentMode)contentMode {
    [self setRefreshableWithStyle:style contentMode:contentMode];
}

- (void)setRefreshableWithContentMode:(UIViewContentMode)contentMode {
    [self setRefreshableWithStyle:WLRefresherStyleWhite contentMode:contentMode];
}

- (void)setRefreshableWithStyle:(WLRefresherStyle)style {
    __weak typeof(self)weakSelf = self;
    run_after_asap(^{
        [WLRefresher refresher:weakSelf.streamView target:weakSelf action:@selector(refresh:) style:style];
    });
}

// MARK: - StreamViewDelegate

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section {
    return self.numberOfItemsBlock ? self.numberOfItemsBlock(self) : [self.items count];
}

- (id)streamView:(StreamView*)streamView viewForItem:(StreamItem*)item {
    id entry = [self.items tryAt:item.index.next.value];
    return [item.metrics viewForItem:item inStreamView:streamView entry:entry];
}

- (NSArray *)streamView:(StreamView *)streamView headerMetricsInSection:(NSUInteger)section {
    return self.headerMetrics;
}

- (NSArray *)streamView:(StreamView *)streamView metricsAt:(StreamIndex *)index {
    return self.metrics;
}

- (NSArray *)streamView:(StreamView *)streamView footerMetricsInSection:(NSUInteger)section {
    return self.footerMetrics;
}

- (NSInteger)streamViewNumberOfSections:(StreamView*)streamView {
    return 1;
}

- (void)streamView:(StreamView*)streamView didSelectItem:(StreamItem*)item {
    id entry = [self.items tryAt:item.index.next.value];
    if (item.metrics.selectionBlock && entry) {
        item.metrics.selectionBlock(entry);
    }
}

- (CGFloat)streamView:(StreamView*)streamView layoutOffset:(StreamLayout*)layout {
    return 0;
}

- (NSInteger)streamView:(StreamView*)streamView layoutNumberOfColumns:(GridLayout*)layout {
    return 3;
}

- (CGFloat)streamView:(StreamView*)streamView layout:(GridLayout*)layout offsetForColumn:(NSInteger)column {
    return 0;
}

- (CGFloat)streamView:(StreamView*)streamView layout:(GridLayout*)layout sizeForColumn:(NSInteger)column {
    return streamView.width / 3;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.scrollDirectionLayoutPrioritizer && scrollView.tracking) {
        if (scrollView.contentSize.height > scrollView.height || self.direction == ScrollDirectionUp) {
            self.direction = [scrollView.panGestureRecognizer translationInView:scrollView].y > 0 ? ScrollDirectionDown : ScrollDirectionUp;
        }
    }
}

- (void)setDirection:(ScrollDirection)direction {
    if (_direction != direction) {
        _direction = direction;
        [self.scrollDirectionLayoutPrioritizer setDefaultState:(direction == ScrollDirectionDown) animated:YES];
    }
}

@end
