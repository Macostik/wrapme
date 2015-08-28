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
}

- (void)setup {
    _items = [NSMutableSet set];
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	[self addGestureRecognizer:tapRecognizer];
	[self addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
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

static NSHashTable *streamViews = nil;

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
        if (!streamViews) {
            streamViews = [NSHashTable weakObjectsHashTable];
        }
        [streamViews addObject:self];
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

#pragma mark - User Actions

- (void)tap:(UITapGestureRecognizer *)recognizer {
    StreamItem *item = [self visibleItemAtPoint:[recognizer locationInView:self]];
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
	for (StreamItem *item in _items) {
		if (CGRectContainsPoint(item.frame, point)) {
			return item;
		}
	}
	return nil;
}

- (void)clear {
	for (StreamItem *item in _items) {
		[item.view removeFromSuperview];
	}
	[_items removeAllObjects];
}

- (void)lock {
    self.locks = MAX(0, self.locks + 1);
}

+ (void)lock {
    for (StreamView *streamView in streamViews) {
        [streamView lock];
    }
}

+ (void)unlock {
    for (StreamView *streamView in streamViews) {
        [streamView unlock];
    }
}

- (void)unlock {
    if (self.locks > 0) {
        self.locks = self.locks - 1;
    }
    if (self.locks == 0 && self.reloadAfterUnlock) {
        self.reloadAfterUnlock = NO;
        [self reload];
    }
}

- (void)reload {
    
    if (self.locks > 0) {
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
    
    for (NSUInteger section = 0; section < self.numberOfSections; ++section) {
        
        StreamIndex *sectionIndex = [StreamIndex index:section];
        
        if ([delegate respondsToSelector:@selector(streamView:sectionHeaderMetricsInSection:)]) {
            NSArray *headers = [delegate streamView:self sectionHeaderMetricsInSection:section];
            for (StreamMetrics *header in headers) {
                [self layout:layout metrics:header index:sectionIndex];
            }
        }
        
        NSInteger numberOfItems = [delegate streamView:self numberOfItemsInSection:section];
        
        for (NSUInteger i = 0; i < numberOfItems; ++i) {
            StreamIndex *index = [[sectionIndex copy] add:i];
            for (StreamMetrics *metrics in [delegate streamView:self metricsAt:index]) {
                [self layout:layout metrics:metrics index:index];
            }
        }
        
        if ([delegate respondsToSelector:@selector(streamView:sectionFooterMetricsInSection:)]) {
            NSArray *footers = [delegate streamView:self sectionFooterMetricsInSection:section];
            for (StreamMetrics *footer in footers) {
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
        view.entry = entry;
        if (item.metrics.viewWillAppearBlock) item.metrics.viewWillAppearBlock(item, entry);
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

@end
