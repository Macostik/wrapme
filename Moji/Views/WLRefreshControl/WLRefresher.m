//
//  WLRefreshControl.m
//  moji
//
//  Created by Ravenpod on 07.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLRefresher.h"
#import "UIView+AnimationHelper.h"
#import "UIScrollView+Additions.h"

static CGFloat WLRefresherContentSize = 44.0f;

@interface WLRefresher ()

@property (readonly, nonatomic) UIScrollView* scrollView;
@property (weak, nonatomic) UIActivityIndicatorView* spinner;
@property (weak, nonatomic) UILabel* candyView;
@property (weak, nonatomic) UIView* contentView;
@property (weak, nonatomic) CAShapeLayer* strokeLayer;

@property (nonatomic) BOOL refreshable;

@end

@implementation WLRefresher

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
	return [[WLRefresher alloc] initWithScrollView:scrollView];
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView {
    UIViewAutoresizing autoresizing;
    CGRect frame = scrollView.bounds;
    frame.origin.y = -scrollView.height;
    autoresizing = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = autoresizing;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.backgroundColor = WLColors.orange;
        [scrollView addSubview:self];
        self.inset = scrollView.contentInset.top;
        self.contentMode = UIViewContentModeCenter;
        [scrollView.panGestureRecognizer addTarget:self action:@selector(dragging:)];
    }
    return self;
}

- (void)setContentMode:(UIViewContentMode)contentMode {
	[super setContentMode:contentMode];
	self.spinner.center = self.candyView.center = self.contentView.centerBoundary;
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

- (UILabel *)candyView {
	if (!_candyView) {
        UILabel* candyView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        candyView.font = [UIFont fontWithName:@"icons" size:24];
        candyView.text = @"e";
        candyView.textAlignment = NSTextAlignmentCenter;
        candyView.clipsToBounds = YES;
        candyView.layer.cornerRadius = candyView.width/2;
        candyView.layer.borderWidth = 1;
        candyView.alpha = 0.25f;
		[self.contentView addSubview:candyView];
        candyView.hidden = YES;
		_candyView = candyView;
	}
	return _candyView;
}

- (CAShapeLayer *)strokeLayer {
    if (!_strokeLayer) {
        CAShapeLayer* layer = [CAShapeLayer layer];

        layer.frame = self.candyView.frame;
        CGFloat size = layer.bounds.size.width/2;
        layer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(size, size) radius:size - 1 startAngle:-M_PI_2 endAngle:2*M_PI - M_PI_2 clockwise:YES].CGPath;
        layer.strokeEnd = 0.0f;
        layer.fillColor = [UIColor clearColor].CGColor;
        layer.lineWidth = 1;
        layer.actions = @{@"strokeEnd":[NSNull null],@"hidden":[NSNull null]};
        [self.contentView.layer addSublayer:layer];
        _strokeLayer = layer;
    }
    return _strokeLayer;
}

- (UIView *)contentView {
	if (!_contentView) {
		UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WLRefresherContentSize, WLRefresherContentSize)];
		contentView.backgroundColor = [UIColor clearColor];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        contentView.translatesAutoresizingMaskIntoConstraints = YES;
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
                [self.spinner startAnimating];
                [self setInset:WLRefresherContentSize animated:animated];
                [self.scrollView setMinimumContentOffsetAnimated:animated];
                [UIView performWithoutAnimation:^{
                    [self sendActionsForControlEvents:UIControlEventValueChanged];
                }];
            }
        } else {
            _refreshing = NO;
			__weak typeof(self)weakSelf = self;
			run_after_asap(^{
				[weakSelf setInset:0 animated:animated];
                [self.spinner stopAnimating];
			});
        }
    }
}

- (void)setInset:(CGFloat)inset animated:(BOOL)animated {
    inset += _inset;
    UIScrollView* scrollView = self.scrollView;
    UIEdgeInsets insets = scrollView.contentInset;
    insets.top = inset;
    [UIView performAnimated:animated animation:^{
        scrollView.contentInset = insets;
    }];
}

- (void)dragging:(UIPanGestureRecognizer*)sender {
    if (!self.enabled) return;
    
    CGFloat offset = self.scrollView.contentOffset.y + _inset;
    
    BOOL hidden = YES;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        hidden = offset > 0;
        self.refreshable = NO;
        if (!hidden) {
            self.contentView.center = CGPointMake(self.width/2.0f, self.height - WLRefresherContentSize/2.0f);
        }
    } else if (offset <= 0 && sender.state == UIGestureRecognizerStateChanged) {
        hidden = NO;
        CGFloat ratio = Smoothstep(0, 1, -offset / (1.3f * WLRefresherContentSize));
        if (self.strokeLayer.strokeEnd != ratio) {
            self.strokeLayer.strokeEnd = ratio;
        }
        self.refreshable = (ratio == 1);
    } else if (sender.state == UIGestureRecognizerStateEnded && _refreshable) {
        __weak typeof(self)weakSelf = self;
        run_after_asap(^{
            [weakSelf setRefreshing:YES animated:YES];
            weakSelf.refreshable = NO;
        });
    }
    
    if (hidden != self.candyView.hidden) {
        self.candyView.hidden = self.strokeLayer.hidden = hidden;
    }
}

- (void)setRefreshable:(BOOL)refreshable {
    if (_refreshable != refreshable) {
        _refreshable = refreshable;
        self.candyView.alpha = refreshable ? 1.0f : 0.25f;
    }
}

- (void)setStyle:(WLRefresherStyle)style {
	_style = style;
	if (style == WLRefresherStyleOrange) {
		self.candyView.textColor = WLColors.orange;
		self.backgroundColor = [UIColor whiteColor];;
		self.spinner.color = WLColors.orange;
        self.strokeLayer.strokeColor = WLColors.orange.CGColor;
        self.candyView.layer.borderColor = WLColors.orange.CGColor;
	} else {
        self.candyView.textColor = [UIColor whiteColor];
        self.backgroundColor = style == WLRefresherStyleWhite ? WLColors.orange : [UIColor clearColor];
        self.spinner.color = [UIColor whiteColor];
        self.strokeLayer.strokeColor = [UIColor whiteColor].CGColor;
        self.candyView.layer.borderColor = [UIColor whiteColor].CGColor;
    }
}

@end
