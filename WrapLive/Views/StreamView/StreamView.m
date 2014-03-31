//
//  TableView.m
//  ScrollAnimation
//
//  Created by Sergey Maximenko on 04.02.13.
//  Copyright (c) 2013 Mobidev. All rights reserved.
//

#import "StreamView.h"
#import "VerticalStreamLayout.h"

static NSString *contentOffsetPath = @"contentOffset";
static NSString *contentSizePath = @"contentSize";
static NSString *panGestureRecognizerStatePath = @"panGestureRecognizer.state";

@interface StreamView () <StreamLayoutItemDelegate>

@property (nonatomic) NSInteger numberOfSections;
@property (strong, nonatomic) NSMutableSet *reusableViews;
@property (strong, nonatomic) NSMutableSet *layoutItems;

@property (nonatomic, strong) StreamLayoutItem *panItem;

@end

@implementation StreamView
{
	CGPoint panOrigin;
	BOOL _refreshing;
	BOOL _loading;
	BOOL _stopLoadData;
	StreamLayoutItem *items;
}

@synthesize layout  = _layout;

- (void)dealloc {
	[self removeObserver:self forKeyPath:contentOffsetPath];
	[self removeObserver:self forKeyPath:panGestureRecognizerStatePath];
}

- (void)setup {
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	[self addGestureRecognizer:tapRecognizer];
	
	//        UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
	//        [self addGestureRecognizer:panRecognizer];
	
	[self addObserver:self forKeyPath:contentOffsetPath options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:panGestureRecognizerStatePath options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)beginRefreshing {
	_refreshing = YES;
	[self.layout beginRefreshingAnimated:YES];
}

- (void)reloadInsets {
	_refreshing = NO;
	_loading = NO;
	[self.layout reloadInsets:_stopLoadData animated:YES];
}

- (void)beginLoading {
	_loading = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (keyPath == contentOffsetPath) {
		[self handleLoadingData];
		dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^(void){
			CGRect rect = (CGRect){self.contentOffset, self.bounds.size};
			for (StreamLayoutItem *item in _layoutItems) {
				item.visible = CGRectIntersectsRect(item.frame, rect);
			}
		});
	} else if (keyPath == panGestureRecognizerStatePath && !_refreshing) {
		if (self.panGestureRecognizer.state == UIGestureRecognizerStateEnded && [self.layout shouldRefreshData]) {
			[self handleRefreshingData];
		}
	}
}

- (void)handleLoadingData {
	if (!_stopLoadData && !_loading) {
		if ([self.layout shouldLoadData]) {
			if ([self.delegate respondsToSelector:@selector(streamViewDidLoadData:)]) {
				[self beginLoading];
				[self.delegate streamViewDidLoadData:self];
			}
		}
	}
}

- (void)handleRefreshingData {
	if ([self.delegate respondsToSelector:@selector(streamViewDidRefreshData:)]) {
		[self beginRefreshing];
		[self.delegate streamViewDidRefreshData:self];
	}
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self setup];
	}
	return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	
	[self setup];
}

- (StreamLayout *)layout {
	if (!_layout) {
		self.layout = [[VerticalStreamLayout alloc] init];
	}
	return _layout;
}

- (void)setLayout:(StreamLayout *)layout {
	_layout = layout;
	
	layout.streamView = self;
}

- (NSMutableSet *)reusableViews {
	if (!_reusableViews) {
		_reusableViews = [NSMutableSet set];
	}
	return _reusableViews;
}

- (NSMutableSet *)layoutItems {
	if (!_layoutItems) {
		_layoutItems = [NSMutableSet set];
	}
	return _layoutItems;
}

#pragma mark - Initialization

- (void)layoutIndexedItems {
	
	StreamLayout* layout = self.layout;
	
	for (NSInteger section = 0; section < self.numberOfSections; ++section) {
		NSInteger numberOfItems = [self.delegate streamView:self numberOfItemsInSection:section];
		
		if ([self.delegate respondsToSelector:@selector(streamView:ratioForSupplementaryViewInSection:)]) {
			StreamIndex index = { section, 0 };
			StreamLayoutItem *item = [layout layoutSupplementaryItem:[self.delegate streamView:self ratioForSupplementaryViewInSection:section]];
			item.index = index;
			item.isSupplementary = YES;
			item.delegate = self;
			[self.layoutItems addObject:item];
		}
		
		[self.layoutItems addObjectsFromArray:[[layout layoutItems:numberOfItems ratio:^CGFloat(StreamLayoutItem* item, NSUInteger itemIndex) {
			StreamIndex index = { section, itemIndex };
			item.index = index;
			item.delegate = self;
			return [self.delegate streamView:self ratioForItemAtIndex:index];
		}] allObjects]];
	}
	
	self.contentSize = self.layout.contentSize;
}

#pragma mark - User Actions

- (void)tap:(UITapGestureRecognizer *)recognizer {
	if ([self.delegate respondsToSelector:@selector(streamView:didSelectItem:)]) {
		StreamLayoutItem *item = [self visibleItemAtPoint:[recognizer locationInView:self]];
		if (item) {
			[self.delegate streamView:self didSelectItem:item];
		}
	}
}

- (void)pan:(UIPanGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		self.panItem = [self visibleItemAtPoint:[recognizer locationInView:self]];
		panOrigin = self.panItem.view.frame.origin;
		[self bringSubviewToFront:self.panItem.view];
	}
	else if (recognizer.state == UIGestureRecognizerStateEnded && self.panItem) {
		StreamLayoutItem *intersectionItem = [self visibleItemAtPoint:self.panItem.view.center];
		
		[UIView beginAnimations:nil context:nil];
		
		if (intersectionItem && intersectionItem != self.panItem) {
			StreamIndex index = self.panItem.index;
			StreamIndex intersectionIndex = intersectionItem.index;
			
			CGRect frame = self.panItem.frame;
			CGRect intersectionFrame = intersectionItem.frame;
			
			self.panItem.index = intersectionIndex;
			intersectionItem.index = index;
			
			self.panItem.frame = intersectionFrame;
			self.panItem.view.frame = intersectionFrame;
			
			intersectionItem.frame = frame;
			intersectionItem.view.frame = frame;
		}
		else {
			self.panItem.view.frame = self.panItem.frame;
		}
		
		[UIView commitAnimations];
		
		self.panItem = nil;
	} else if (self.panItem) {
		CGPoint translation = [recognizer translationInView:self];
		CGRect frame = self.panItem.view.frame;
		frame.origin = CGPointMake(panOrigin.x + translation.x, panOrigin.y + translation.y);
		self.panItem.view.frame = frame;
	}
}

- (StreamLayoutItem *)visibleItemAtPoint:(CGPoint)point {
	for (StreamLayoutItem *item in self.layoutItems) {
		if (CGRectContainsPoint(item.frame, point)) {
			return item;
		}
	}
	return nil;
}

- (void)clearData {
	for (StreamLayoutItem *item in self.layoutItems) {
		[item.view removeFromSuperview];
	}
	[self.layoutItems removeAllObjects];
}

- (void)reloadData {
	[self reloadData:YES];
}

- (void)reloadData:(BOOL)stop {
	_stopLoadData = stop;
	
	[self reloadInsets];
	
	[self clearData];
	
	StreamLayout *layout = self.layout;
	
	if ([self.delegate respondsToSelector:@selector(streamViewNumberOfColumns:)]) {
		layout.numberOfColumns = [self.delegate streamViewNumberOfColumns:self];
	} else {
		layout.numberOfColumns = 1;
	}
	
	if ([self.delegate respondsToSelector:@selector(streamViewSpacing:)]) {
		layout.spacing = [self.delegate streamViewSpacing:self];
	} else {
		layout.spacing = 5.0f;
	}
	
	[layout prepareLayout];
	
	if ([self.delegate respondsToSelector:@selector(streamViewNumberOfSections:)]) {
		self.numberOfSections = [self.delegate streamViewNumberOfSections:self];
	} else {
		self.numberOfSections = 1;
	}
	
	if ([self.delegate respondsToSelector:@selector(streamView:initialRangeForColumn:)]) {
		for (NSInteger column = 0; column < layout.numberOfColumns; ++column) {
			CGFloat range = [self.delegate streamView:self initialRangeForColumn:column];
			[layout setRange:range atIndex:column];
		}
	}
	
	[self layoutIndexedItems];
	
	[self updateVisibility];
}

- (id)reusableViewOfClass:(Class)viewClass {
	return [self reusableViewOfClass:viewClass forItem:nil];
}

- (id)reusableViewOfClass:(Class)viewClass forItem:(StreamLayoutItem *)item {
	for (UIView *view in self.reusableViews) {
		if (!view.superview && [view isKindOfClass:viewClass]) {
			return view;
		}
	}
	if (_reusableViewLoadingType == StreamViewReusableViewLoadingTypeInit) {
		CGRect frame = item ? item.frame : CGRectMake(0, 0, 100, 100);
		return [[viewClass alloc] initWithFrame:frame];
	} else if (_reusableViewLoadingType == StreamViewReusableViewLoadingTypeNib) {
		NSArray *objects = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(viewClass) owner:nil options:nil];
		for (id object in objects) {
			if ([object isKindOfClass:viewClass]) {
				return object;
			}
		}
	}
	return nil;
}

- (void)updateVisibility {
	CGRect rect = (CGRect){self.contentOffset, self.bounds.size};
	for (StreamLayoutItem *item in _layoutItems) {
		item.visible = CGRectIntersectsRect(item.frame, rect);
	}
}

- (void)clearReusingViews {
	NSInteger count = 0;
	
	NSMutableSet *viewsToRemove = [NSMutableSet set];
	
	for (UIView *view in self.reusableViews) {
		if (!view.superview) {
			if (count < 5) {
				count++;
			} else {
				[viewsToRemove addObject:view];
			}
		}
	}
	
	for (UIView *view in viewsToRemove) {
		[self.reusableViews removeObject:view];
	}
}

#pragma mark - PICStreamLayoutItemDelegate

- (void)streamLayoutItemWillBecomeInvisible:(StreamLayoutItem *)item {
	[item.view removeFromSuperview];
}

- (void)streamLayoutItemWillBecomeVisible:(StreamLayoutItem *)item {
	UIView *view = nil;
	
	if (item.isSupplementary && [self.delegate respondsToSelector:@selector(streamView:supplementaryViewInSection:)]) {
		view = [self.delegate streamView:self supplementaryViewInSection:item.index.section];
	} else {
		view = [self.delegate streamView:self viewForItem:item];
	}
	
	if (view) {
		item.view = view;
		[UIView setAnimationsEnabled:NO];
		view.frame = item.frame;
		[UIView setAnimationsEnabled:YES];
		
		if (view.superview != self) {
			[self addSubview:view];
		}
		
		[self.reusableViews addObject:view];
	}
}

@end

@implementation StreamLayoutItem

- (void)setVisible:(BOOL)visible {
	if (_visible != visible) {
		if (visible) {
			[self.delegate streamLayoutItemWillBecomeVisible:self];
		} else {
			[self.delegate streamLayoutItemWillBecomeInvisible:self];
		}
		_visible = visible;
	}
}

@end
