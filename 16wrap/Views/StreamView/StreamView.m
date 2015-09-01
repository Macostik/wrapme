//
//  TableView.m
//  ScrollAnimation
//
//  Created by Ravenpod on 04.02.13.
//  Copyright (c) 2013 Ravenpod. All rights reserved.
//

#import "StreamView.h"
#import "StreamLayout.h"
#import "StreamMetrics.h"

static NSString *StreamViewCommonLocksChanged = @"StreamViewCommonLocksChanged";

@interface StreamView ()

@property (nonatomic) NSInteger numberOfSections;

@property (strong, nonatomic) NSMutableSet *items;

@property (nonatomic) BOOL reloadAfterUnlock;

@property (nonatomic) NSUInteger locks;

@end

@implementation StreamView

@synthesize layout  = _layout;

@dynamic delegate;

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"contentOffset"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:StreamViewCommonLocksChanged object:nil];
}

- (void)setup {
    _items = [NSMutableSet set];
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	[self addGestureRecognizer:tapRecognizer];
	[self addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locksChanged) name:StreamViewCommonLocksChanged object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self updateVisibility];
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self setup];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (StreamLayout *)layout {
    if (!_layout) {
        self.layout = [[StreamLayout alloc] init];
    }
    return _layout;
}

- (void)setLayout:(StreamLayout *)layout {
	_layout = layout;
	layout.streamView = self;
}

- (BOOL)horizontal {
    return self.layout.horizontal;
}

- (void)setHorizontal:(BOOL)horizontal {
    self.layout.horizontal = horizontal;
}

- (void)clear {
    for (StreamItem *item in _items) {
        [item.view removeFromSuperview];
    }
    [_items removeAllObjects];
}

static NSUInteger commonLocks = 0;

+ (void)lock {
    commonLocks = MAX(0, commonLocks + 1);
}

+ (void)unlock {
    if (commonLocks > 0) {
        commonLocks = commonLocks - 1;
        [[NSNotificationCenter defaultCenter] postNotificationName:StreamViewCommonLocksChanged object:nil];
    }
}

- (void)locksChanged {
    if (self.locks == 0 && commonLocks == 0 && self.reloadAfterUnlock) {
        self.reloadAfterUnlock = NO;
        [self reload];
    }
}

- (void)lock {
    self.locks = MAX(0, self.locks + 1);
}

- (void)unlock {
    if (self.locks > 0) {
        self.locks = self.locks - 1;
        [self locksChanged];
    }
}

- (void)reload {
    
    if (self.locks > 0 && commonLocks > 0) {
        self.reloadAfterUnlock = YES;
        return;
    }
    
    [self clear];
    
    StreamLayout *layout = self.layout;
    
    [layout prepare];
    
    id <StreamViewDelegate> delegate = self.delegate;
    
    if ([delegate respondsToSelector:@selector(streamViewNumberOfSections:)]) {
        self.numberOfSections = [delegate streamViewNumberOfSections:self];
    } else {
        self.numberOfSections = 1;
    }
    
    if ([delegate respondsToSelector:@selector(streamViewHeaderMetrics:)]) {
        NSArray *headers = [delegate streamViewHeaderMetrics:self];
        for (StreamMetrics *header in headers) {
            [self layout:layout metrics:header index:nil];
        }
    }
    
    BOOL empty = YES;
    
    for (NSUInteger section = 0; section < self.numberOfSections; ++section) {
        
        StreamIndex *sectionIndex = [StreamIndex index:section];
        
        if ([delegate respondsToSelector:@selector(streamView:sectionHeaderMetricsInSection:)]) {
            NSArray *headers = [delegate streamView:self sectionHeaderMetricsInSection:section];
            for (StreamMetrics *header in headers) {
                empty = NO;
                [self layout:layout metrics:header index:sectionIndex];
            }
        }
        
        NSInteger numberOfItems = [delegate streamView:self numberOfItemsInSection:section];
        
        for (NSUInteger i = 0; i < numberOfItems; ++i) {
            empty = NO;
            StreamIndex *index = [[sectionIndex copy] add:i];
            for (StreamMetrics *metrics in [delegate streamView:self metricsAt:index]) {
                [self layout:layout metrics:metrics index:index];
            }
        }
        
        if ([delegate respondsToSelector:@selector(streamView:sectionFooterMetricsInSection:)]) {
            NSArray *footers = [delegate streamView:self sectionFooterMetricsInSection:section];
            for (StreamMetrics *footer in footers) {
                empty = NO;
                [self layout:layout metrics:footer index:sectionIndex];
            }
        }
        
        [layout prepareForNextSection];
    }
    
    if ([delegate respondsToSelector:@selector(streamViewFooterMetrics:)]) {
        NSArray *footers = [delegate streamViewFooterMetrics:self];
        for (StreamMetrics *footer in footers) {
            [self layout:layout metrics:footer index:nil];
        }
    }
    
    if (empty) {
        if ([delegate respondsToSelector:@selector(streamViewPlaceholderMetrics:)]) {
            StreamMetrics *placeholder = [delegate streamViewPlaceholderMetrics:self];
            CGSize size = self.frame.size;
            UIEdgeInsets insets = self.contentInset;
            if (self.horizontal) {
                placeholder.size = size.width - insets.left - insets.right - layout.contentSize.width;
            } else {
                placeholder.size = size.height - insets.top - insets.bottom - layout.contentSize.height;
            }
            [self layout:layout metrics:placeholder index:nil];
        }
    }
    
    [layout finalize];
    
    self.contentSize = layout.contentSize;
    
    [self updateVisibility];
}

- (void)layout:(StreamLayout*)layout metrics:(StreamMetrics*)metrics index:(StreamIndex*)index {
    if (![metrics hiddenAt:index]) {
        StreamItem *item = [[StreamItem alloc] init];
        item.index = index;
        item.metrics = metrics;
        [layout layout:item];
        if (!CGSizeEqualToSize(item.frame.size, CGSizeZero)) {
            [_items addObject:item];
        }
    }
}

- (id)viewForItem:(StreamItem *)item {
    
    StreamReusableView *view = [item.metrics loadView];
    
    if (view) {
        view.frame = item.frame;
        item.view = view;
        id entry = nil;
        if ([self.delegate respondsToSelector:@selector(streamView:entryAt:)]) {
            entry = [self.delegate streamView:self entryAt:item.index];
        }
        if (item.metrics.prepareAppearingBlock) item.metrics.prepareAppearingBlock(item, entry);
        view.entry = entry;
        if (item.metrics.finalizeAppearingBlock) item.metrics.finalizeAppearingBlock(item, entry);
        view.frame = item.frame;
    }
    
    return view;
}

- (void)updateVisibility {
    CGRect rect = (CGRect){self.contentOffset, self.bounds.size};
    
    for (StreamItem *item in _items) {
        
        BOOL visible = CGRectIntersectsRect(item.frame, rect);
        if (item.visible != visible) {
            item.visible = visible;
            if (visible) {
                StreamReusableView *view = [self viewForItem:item];
                if (view) {
                    [self insertSubview:view atIndex:0];
                }
            } else {
                StreamReusableView *view = item.view;
                if (view) {
                    [view removeFromSuperview];
                    [item.metrics.reusableViews addObject:view];
                }
            }
        }
    }
}

// MARK: - User Actions

- (void)tap:(UITapGestureRecognizer *)recognizer {
    [self touchedAt:[recognizer locationInView:self]];
}

- (void)touchedAt:(CGPoint)point {
    StreamItem *item = [self visibleItemAtPoint:point];
    if (item) {
        if (item.selected) {
            item.selected = NO;
            self.selectedItem = nil;
        } else {
            item.selected = YES;
            self.selectedItem.selected = NO;
            self.selectedItem = item;
        }
        
        if ([self.delegate respondsToSelector:@selector(streamView:entryAt:)]) {
            [item.metrics select:item entry:[self.delegate streamView:self entryAt:item.index]];
        }
    }
}

- (StreamItem *)visibleItemAtPoint:(CGPoint)point {
    return [self itemPassingTest:^BOOL(StreamItem *item) {
        return CGRectContainsPoint(item.frame, point);
    }];
}

- (StreamItem *)itemPassingTest:(BOOL (^)(StreamItem *))test {
    if (test) {
        for (StreamItem *item in _items) {
            if (test(item)) {
                return item;
            }
        }
    }
    return nil;
}

- (void)scrollToItem:(StreamItem *)item animated:(BOOL)animated {
    [self scrollRectToVisible:item.frame animated:animated];
}

@end
