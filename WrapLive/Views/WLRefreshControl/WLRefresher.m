//
//  WLRefreshControl.m
//  WrapLive
//
//  Created by Sergey Maximenko on 07.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLRefresher.h"
#import "WLSupportFunctions.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "WLBlocks.h"
#import <AFNetworking/AFURLConnectionOperation.h>
#import "UIView+AnimationHelper.h"
#import "UIScrollView+Additions.h"

static NSString* WlRefresherContentOffsetKeyPath = @"contentOffset";

static NSString* WlRefresherDraggingStateKeyPath = @"state";

static CGFloat WLRefresherContentSize = 44.0f;

@interface WLRefresher ()

@property (readonly, nonatomic) UIScrollView* scrollView;
@property (nonatomic) BOOL horizontal;
@property (weak, nonatomic) UIActivityIndicatorView* spinner;
@property (weak, nonatomic) UIImageView* arrowView;
@property (weak, nonatomic) UIView* contentView;
@property (nonatomic) CGFloat inset;
@property (weak, nonatomic) CAShapeLayer* strokeLayer;

@property (nonatomic) BOOL refreshable;

@end

@implementation WLRefresher

@synthesize refreshing = _refreshing;

- (void)willMoveToSuperview:(UIView *)newSuperview {
	
    UIView *oldSuperview = self.superview;
	[oldSuperview removeObserver:self
						forKeyPath:WlRefresherContentOffsetKeyPath
						   context:NULL];
	if (newSuperview) {
		[newSuperview addObserver:self
					   forKeyPath:WlRefresherContentOffsetKeyPath
						  options:NSKeyValueObservingOptionNew
						  context:NULL];
	}
		
	[super willMoveToSuperview:newSuperview];
}

- (UIScrollView *)scrollView {
	return (id)self.superview;
}

- (void)setEnabled:(BOOL)enabled {
	[super setEnabled:enabled];
	self.hidden = !enabled;
}

+ (WLRefresher *)refresher:(UIScrollView *)scrollView target:(id)target action:(SEL)action {
    return [self refresher:scrollView target:target action:action style:WLRefresherStyleWhite];
}

+ (WLRefresher *)refresher:(UIScrollView *)scrollView target:(id)target action:(SEL)action style:(WLRefresherStyle)style {
    WLRefresher* refresher = [self refresher:scrollView];
	[refresher addTarget:target action:action forControlEvents:UIControlEventValueChanged];
    refresher.style = style;
	return refresher;
}

+ (WLRefresher*)refresher:(UIScrollView *)scrollView {
	return [self refresher:scrollView horizontal:NO];
}

+ (WLRefresher*)refresher:(UIScrollView *)scrollView horizontal:(BOOL)horizontal {
    UIViewAutoresizing autoresizing;
    CGRect frame = (CGRect){.size = scrollView.size};
	CGRect contentFrame;
	if (horizontal) {
        frame.origin.x = -scrollView.width;
		contentFrame = CGRectMake(frame.size.width - WLRefresherContentSize, 0, WLRefresherContentSize, frame.size.height);
        autoresizing = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
	} else {
        frame.origin.y = -scrollView.height;
		contentFrame = CGRectMake(0, frame.size.height - WLRefresherContentSize, frame.size.width, WLRefresherContentSize);
        autoresizing = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
	}
	WLRefresher* refresher = [[WLRefresher alloc] initWithFrame:frame];
    refresher.autoresizingMask = autoresizing;
	refresher.horizontal = horizontal;
	refresher.backgroundColor = [UIColor WL_orangeColor];
	[scrollView addSubview:refresher];
    refresher.inset = horizontal ? scrollView.contentInset.left : scrollView.contentInset.top;
	refresher.contentView.frame = contentFrame;
	refresher.contentMode = UIViewContentModeCenter;
	return refresher;
}

- (void)setContentMode:(UIViewContentMode)contentMode {
	[super setContentMode:contentMode];
	CGPoint center = self.contentView.centerBoundary;
	if (!_horizontal && contentMode == UIViewContentModeLeft) {
		center.x = center.y;
    }
	self.spinner.center = center;
	self.arrowView.center = center;
}

- (UIActivityIndicatorView *)spinner {
	if (!_spinner) {
		UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		spinner.hidesWhenStopped = YES;
		[self.contentView addSubview:spinner];
		_spinner = spinner;
	}
	return _spinner;
}

- (UIImageView *)arrowView {
	if (!_arrowView) {
        UIImageView* arrowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        arrowView.contentMode = UIViewContentModeCenter;
        arrowView.clipsToBounds = YES;
        arrowView.layer.cornerRadius = arrowView.width/2;
        arrowView.layer.borderWidth = 1;
        arrowView.alpha = 0.25f;
		[self.contentView addSubview:arrowView];
		_arrowView = arrowView;
	}
	return _arrowView;
}

- (CAShapeLayer *)strokeLayer {
    if (!_strokeLayer) {
        CAShapeLayer* layer = [CAShapeLayer layer];

        layer.frame = self.arrowView.frame;
        CGFloat size = layer.bounds.size.width/2;
        layer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(size, size) radius:size - 1 startAngle:-M_PI_2 endAngle:2*M_PI - M_PI_2 clockwise:YES].CGPath;
        layer.strokeEnd = 0.0f;
        layer.fillColor = [UIColor clearColor].CGColor;
        layer.lineWidth = 1;
        
        [self.contentView.layer addSublayer:layer];
        _strokeLayer = layer;
    }
    return _strokeLayer;
}

- (UIView *)contentView {
	if (!_contentView) {
		UIView* contentView = [[UIView alloc] init];
		contentView.backgroundColor = [UIColor clearColor];
        contentView.autoresizingMask = self.autoresizingMask;
		[self addSubview:contentView];
		_contentView = contentView;
	}
	return _contentView;
}

- (void)setRefreshing:(BOOL)refreshing {
    [self setRefreshing:refreshing animated:NO];
}

- (void)setRefreshing:(BOOL)refreshing animated:(BOOL)animated {
    if (_refreshing != refreshing) {
        if (refreshing) {
            if (_refreshable) {
                _refreshing = refreshing;
                [self setArrowViewHidden:YES];
                [self setInset:WLRefresherContentSize animated:animated];
                [self.scrollView scrollToTopAnimated:animated];
                [UIView performWithoutAnimation:^{
                    [self sendActionsForControlEvents:UIControlEventValueChanged];
                }];
            }
        } else {
            _refreshing = NO;
			__weak typeof(self)weakSelf = self;
			run_after_asap(^{
				[weakSelf setInset:0 animated:animated];
				[weakSelf setArrowViewHidden:NO];
			});
        }
    }
}

- (void)setInset:(CGFloat)inset animated:(BOOL)animated {
    inset += _inset;
    UIScrollView* scrollView = self.scrollView;
    UIEdgeInsets insets = scrollView.contentInset;
    if (_horizontal) {
        insets.left = inset;
    } else {
        insets.top = inset;
    }
    [UIView performAnimated:animated animation:^{
        scrollView.contentInset = insets;
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (self.enabled) {
        UIScrollView* sv = self.scrollView;
        if (keyPath == WlRefresherContentOffsetKeyPath) {
            CGPoint offset = sv.contentOffset;
            [self didChangeContentOffset:_horizontal ? (offset.x + _inset) : (offset.y + _inset) tracking:sv.tracking];
        } else if (keyPath == WlRefresherDraggingStateKeyPath) {
            if (sv.panGestureRecognizer.state == UIGestureRecognizerStateEnded && _refreshable) {
                __weak typeof(self)weakSelf = self;
                run_after_asap(^{
                    [weakSelf setRefreshing:YES animated:YES];
                });
            }
        }
	}
}

- (void)setRefreshable:(BOOL)refreshable {
    if (_refreshable != refreshable) {
        _refreshable = refreshable;
        self.arrowView.alpha = refreshable ? 1.0f : 0.25f;
        if (refreshable) {
            [self.scrollView.panGestureRecognizer addObserver:self
                           forKeyPath:WlRefresherDraggingStateKeyPath
                              options:NSKeyValueObservingOptionNew
                              context:NULL];
        } else {
            [self.scrollView.panGestureRecognizer removeObserver:self
                                 forKeyPath:WlRefresherDraggingStateKeyPath
                                    context:NULL];
        }
    }
}

- (void)didChangeContentOffset:(CGFloat)offset tracking:(BOOL)tracking {
    if (offset > 0) return;
    BOOL hidden = !tracking;
    if (self.arrowView.hidden != hidden) {
        self.arrowView.hidden = hidden;
    }
    CGFloat ratio = 0;
    ratio = Smoothstep(0, 1, -offset / (1.3f * WLRefresherContentSize));
    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    self.strokeLayer.strokeEnd = hidden ? 0.0f : ratio;
    [CATransaction commit];
    self.refreshable = (ratio == 1);
}

- (void)setArrowViewHidden:(BOOL)hidden {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    self.arrowView.hidden = hidden ? YES : !self.scrollView.tracking;
    self.strokeLayer.hidden = hidden;
    [CATransaction commit];
    if (hidden) {
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
    }
}

- (void)setStyle:(WLRefresherStyle)style {
	_style = style;
	if (style == WLRefresherStyleOrange) {
		self.arrowView.image = [UIImage imageNamed:@"ic_middle_candy"];
		self.backgroundColor = [UIColor whiteColor];
		self.spinner.color = [UIColor WL_orangeColor];
        self.strokeLayer.strokeColor = [UIColor WL_orangeColor].CGColor;
        self.arrowView.layer.borderColor = [UIColor WL_orangeColor].CGColor;
	} else {
		self.arrowView.image = [UIImage imageNamed:@"ic_refresh_candy_white"];
		self.backgroundColor = [UIColor WL_orangeColor];
		self.spinner.color = [UIColor whiteColor];
        self.strokeLayer.strokeColor = [UIColor whiteColor].CGColor;
        self.arrowView.layer.borderColor = [UIColor whiteColor].CGColor;
	}
}

- (void)setOperation:(AFURLConnectionOperation *)operation {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AFNetworkingOperationDidFinishNotification object:nil];
    
    if (operation) {
        if (![operation isFinished]) {
            if (![operation isExecuting]) {
                [self setRefreshing:NO animated:YES];
            }
            [notificationCenter addObserver:self selector:@selector(af_endRefreshing) name:AFNetworkingOperationDidFinishNotification object:operation];
        }
    }
}

- (void)af_endRefreshing {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setRefreshing:NO animated:YES];
    });
}

@end
