//
//  TableView.m
//  ScrollAnimation
//
//  Created by Ravenpod on 04.02.13.
//  Copyright (c) 2013 Ravenpod. All rights reserved.
//

#import "StreamView.h"
#import "StreamLayout.h"

static NSString *contentOffsetPath = @"contentOffset";

@interface StreamView ()

@property (nonatomic) NSInteger numberOfSections;

@property (strong, nonatomic) NSMutableSet *views;

@property (strong, nonatomic) NSMutableSet *items;

@property (nonatomic) BOOL reloadAfterUnlock;

@property (nonatomic) NSUInteger locks;

@property (strong, nonatomic) NSArray *updatingRunLoopModes;

@end

@implementation StreamView

@synthesize layout  = _layout;

@dynamic delegate;

- (void)dealloc {
	[self removeObserver:self forKeyPath:contentOffsetPath];
}

- (void)setup {
    self.updatingRunLoopModes = @[NSRunLoopCommonModes];
    _items = [NSMutableSet set];
    _views = [NSMutableSet set];
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	[self addGestureRecognizer:tapRecognizer];
	[self addObserver:self forKeyPath:contentOffsetPath options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (keyPath == contentOffsetPath) {
        [self performSelector:@selector(updateVisibility) withObject:nil afterDelay:0.0f inModes:self.updatingRunLoopModes];
	}
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
	if ([self.delegate respondsToSelector:@selector(streamView:didSelectItem:)]) {
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
			[self.delegate streamView:self didSelectItem:item];
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
    
    StreamMetrics *metrics = item.metrics;
    
	for (StreamReusableView *view in _views) {
		if (!view.superview && view.metrics == metrics) {
            [view prepareForReuse];
			return view;
		}
	}
    
    UINib *nib = metrics.nib;
    if (!nib && metrics.identifier) {
        nib = [UINib nibWithNibName:metrics.identifier bundle:metrics.nibOwner];
    }
    if (nib) {
        NSArray *objects = [nib instantiateWithOwner:metrics.nibOwner options:nil];
        for (StreamReusableView *object in objects) {
            if ([object isKindOfClass:[StreamReusableView class]]) {
                object.metrics = metrics;
                return object;
            }
        }
    }
	return nil;
}

- (void)updateVisibility {
	CGRect rect = (CGRect){self.contentOffset, self.bounds.size};
    
	for (StreamItem *item in _items) {
        
		BOOL visible = CGRectIntersectsRect(item.frame, rect);
        if (item.visible != visible) {
            
            if (visible) {
                
                StreamReusableView *view = [self.delegate streamView:self viewForItem:item];
                
                if (view) {
                    item.view = view;
                    [UIView setAnimationsEnabled:NO];
                    view.frame = item.frame;
                    [UIView setAnimationsEnabled:YES];
                    
                    if (view.superview != self) {
                        [self insertSubview:view atIndex:0];
                    }
                    
                    [_views addObject:view];
                }
                
            } else {
                
                [item.view removeFromSuperview];
                
            }
            item.visible = visible;
        }
	}
}

- (void)clearReusingViews {
	NSInteger count = 0;
	
	NSMutableSet *viewsToRemove = [NSMutableSet set];
	
	for (UIView *view in _views) {
		if (!view.superview) {
			if (count < 5) {
				count++;
			} else {
				[viewsToRemove addObject:view];
			}
		}
	}
	
	for (UIView *view in viewsToRemove) {
		[_views removeObject:view];
	}
}

@end
