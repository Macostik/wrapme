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

@interface StreamView () <StreamItemDelegate>

@property (nonatomic) NSInteger numberOfSections;

@property (strong, nonatomic) NSMutableSet *views;

@property (strong, nonatomic) NSMutableSet *items;

@property (nonatomic) BOOL reloadAfterUnlock;

@property (nonatomic) NSUInteger locks;

@end

@implementation StreamView

@synthesize layout  = _layout;

@dynamic delegate;

- (void)dealloc {
	[self removeObserver:self forKeyPath:contentOffsetPath];
}

- (void)setup {
    _items = [NSMutableSet set];
    _views = [NSMutableSet set];
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	[self addGestureRecognizer:tapRecognizer];
	[self addObserver:self forKeyPath:contentOffsetPath options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (keyPath == contentOffsetPath) {
		dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^(void){
			CGRect rect = (CGRect){self.contentOffset, self.bounds.size};
			for (StreamItem *item in _items) {
				item.visible = CGRectIntersectsRect(item.frame, rect);
			}
		});
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
    
    for (NSUInteger section = 0; section < self.numberOfSections; ++section) {
        NSInteger numberOfItems = [delegate streamView:self numberOfItemsInSection:section];
        
        for (NSUInteger i = 0; i < numberOfItems; ++i) {
            StreamItem *item = [[StreamItem alloc] init];
            item.delegate = self;
            StreamIndex *index = item.index = [[StreamIndex index:section] add:i];
            StreamMetrics *metrics = item.metrics = [delegate streamView:self metricsAt:index];
            
            for (StreamMetrics *header in metrics.headers) {
                StreamIndex *headerIndex = [[(StreamIndex*)[index copy] add:0] add:[metrics.headers indexOfObject:header]];
                if (![header.hidden valueAt:headerIndex]) {
                    StreamItem *item = [[StreamItem alloc] init];
                    item.delegate = self;
                    item.index = headerIndex;
                    item.metrics = header;
                    [layout layout:item];
                    [_items addObject:item];
                }
            }
            
            if (![metrics.hidden valueAt:index]) {
                [layout layout:item];
                [_items addObject:item];
            }
            
            for (StreamMetrics *footer in metrics.footers) {
                StreamIndex *footerIndex = [[(StreamIndex*)[index copy] add:1] add:[metrics.footers indexOfObject:footer]];
                if (![footer.hidden valueAt:footerIndex]) {
                    StreamItem *item = [[StreamItem alloc] init];
                    item.delegate = self;
                    item.index = footerIndex;
                    item.metrics = footer;
                    [layout layout:item];
                    [_items addObject:item];
                }
            }
            
            
        }
        
        [layout prepareForNextSection];
    }
    
    [layout finalize];
    
    self.contentSize = layout.contentSize;
	
	[self updateVisibility];
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
        nib = [UINib nibWithNibName:metrics.identifier bundle:nil];
    }
    if (nib) {
        NSArray *objects = [nib instantiateWithOwner:nil options:nil];
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
		item.visible = CGRectIntersectsRect(item.frame, rect);
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

#pragma mark - StreamItemDelegate

- (void)streamItemWillBecomeInvisible:(StreamItem *)item {
	[item.view removeFromSuperview];
}

- (void)streamItemWillBecomeVisible:(StreamItem *)item {
	StreamReusableView *view = [self.delegate streamView:self viewForItem:item];
	
	if (view) {
		item.view = view;
		[UIView setAnimationsEnabled:NO];
		view.frame = item.frame;
		[UIView setAnimationsEnabled:YES];
		
		if (view.superview != self) {
			[self addSubview:view];
		}
		
		[_views addObject:view];
	}
}

@end
