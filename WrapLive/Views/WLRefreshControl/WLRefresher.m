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

static NSString* WlRefresherContentOffsetKeyPath = @"contentOffset";

static CGFloat WLRefresherContentSize = 88.0f;

@interface WLRefresher ()

@property (readonly, nonatomic) UIScrollView* scrollView;
@property (nonatomic) WLRefresherScrollDirection direction;
@property (strong, nonatomic) void (^refreshBlock) (WLRefresher *);
@property (weak, nonatomic) UIActivityIndicatorView* spinner;
@property (weak, nonatomic) UIImageView* arrowView;
@property (weak, nonatomic) UIView* contentView;
@property (nonatomic) UIEdgeInsets defaultContentInsets;

@end

@implementation WLRefresher
{
	BOOL _refreshing;
}

@synthesize refreshing = _refreshing;

- (void)willMoveToSuperview:(UIView *)newSuperview {
	
	[self.superview removeObserver:self
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

+ (WLRefresher *)refresherWithScrollView:(UIScrollView *)scrollView refreshBlock:(void (^)(WLRefresher *))refreshBlock {
	WLRefresher* refresher = [self refresherWithScrollView:scrollView];
	refresher.refreshBlock = refreshBlock;
	[refresher addTarget:refresher action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
	return refresher;
}

+ (WLRefresher *)refresherWithScrollView:(UIScrollView *)scrollView target:(id)target action:(SEL)action {
    return [self refresherWithScrollView:scrollView target:target action:action colorScheme:WLRefresherColorSchemeWhite];
}

+ (WLRefresher *)refresherWithScrollView:(UIScrollView *)scrollView target:(id)target action:(SEL)action colorScheme:(WLRefresherColorScheme)colorScheme {
    WLRefresher* refresher = [self refresherWithScrollView:scrollView];
	[refresher addTarget:target action:action forControlEvents:UIControlEventValueChanged];
    refresher.colorScheme = colorScheme;
	return refresher;
}

+ (WLRefresher*)refresherWithScrollView:(UIScrollView *)scrollView {
	WLRefresherScrollDirection direction = scrollView.frame.size.height > scrollView.frame.size.width ? WLRefresherScrollDirectionVertical : WLRefresherScrollDirectionHorizontal;
	return [self refresherWithScrollView:scrollView direction:direction];
}

+ (WLRefresher*)refresherWithScrollView:(UIScrollView *)scrollView direction:(WLRefresherScrollDirection)direction {
	CGRect frame;
	CGRect contentFrame;
	if (direction == WLRefresherScrollDirectionHorizontal) {
		frame = CGRectMake(-scrollView.width, 0, scrollView.width, scrollView.height);
		contentFrame = CGRectMake(frame.size.width - WLRefresherContentSize, 0, WLRefresherContentSize, frame.size.height);
	} else {
		frame = CGRectMake(0, -scrollView.height, scrollView.width, scrollView.height);
		contentFrame = CGRectMake(0, frame.size.height - WLRefresherContentSize, frame.size.width, WLRefresherContentSize);
	}
	WLRefresher* refresher = [[WLRefresher alloc] initWithFrame:frame];
	refresher.direction = direction;
	refresher.backgroundColor = [UIColor WL_orangeColor];
	[scrollView addSubview:refresher];
    refresher.defaultContentInsets = scrollView.contentInset;
	refresher.contentView.frame = contentFrame;
	refresher.contentMode = UIViewContentModeCenter;
	return refresher;
}

- (void)setContentMode:(UIViewContentMode)contentMode {
	[super setContentMode:contentMode];
	
	CGPoint center;
	
	if (self.direction == WLRefresherScrollDirectionHorizontal) {
		center = self.contentView.centerBoundary;
	} else {
		if (contentMode == UIViewContentModeLeft) {
			center = CGPointMake(self.contentView.height/2, self.contentView.height/2);
		} else {
			center = self.contentView.centerBoundary;
		}
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
		UIImageView* arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_refresh_arrow"]];
		[self.contentView addSubview:arrowView];
		_arrowView = arrowView;
	}
	return _arrowView;
}

- (UIView *)contentView {
	if (!_contentView) {
		UIView* contentView = [[UIView alloc] init];
		contentView.backgroundColor = [UIColor clearColor];
		[self addSubview:contentView];
		_contentView = contentView;
	}
	return _contentView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (self.enabled && keyPath == WlRefresherContentOffsetKeyPath) {
		[self didChangeContentOffset:self.scrollView.contentOffset];
	}
}

- (void)didChangeContentOffset:(CGPoint)offset {
	if (self.direction == WLRefresherScrollDirectionHorizontal) {
        self.arrowView.alpha = offset.x >= -self.defaultContentInsets.left ? 0.0f : 1.0f;
		if (offset.x < 0) {
			[self setArrowViewRotated:(offset.x <= -(66 + self.defaultContentInsets.left)) animated:YES];
			if (!self.scrollView.dragging) {
				[self didEndDragging:self.scrollView.contentOffset];
			}
		}
	} else {
        self.arrowView.alpha = offset.y >= -self.defaultContentInsets.top ? 0.0f : 1.0f;
		if (offset.y < 0) {
			[self setArrowViewRotated:(offset.y <= -(66 + self.defaultContentInsets.top)) animated:YES];
			if (!self.scrollView.dragging) {
				[self didEndDragging:self.scrollView.contentOffset];
			}
		}
	}
}

- (void)setArrowViewRotated:(BOOL)rotated animated:(BOOL)animated {
	
	CGAffineTransform transform;
	
	if (self.direction == WLRefresherScrollDirectionHorizontal) {
		transform = CGAffineTransformMakeRotation(rotated ? M_PI_2 : (M_PI_2 + M_PI));
	} else {
		transform = CGAffineTransformMakeRotation(rotated ? M_PI : 2*M_PI);
	}
	
	if (!CGAffineTransformEqualToTransform(self.arrowView.transform, transform)) {
		if (animated) {
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		}
		self.arrowView.transform = transform;
		if (animated) {
			[UIView commitAnimations];
		}
	}
}

- (void)didEndDragging:(CGPoint)offset {
	
	if (self.direction == WLRefresherScrollDirectionHorizontal) {
		if (!_refreshing && offset.x <= -(66 + self.defaultContentInsets.left)) {
			_refreshing = YES;
			[self.spinner startAnimating];
			self.arrowView.hidden = YES;
			[UIView beginAnimations:nil context:nil];
			UIEdgeInsets insets = self.scrollView.contentInset;
			insets.left = 88 + self.defaultContentInsets.left;
			self.scrollView.contentInset = insets;
			[UIView commitAnimations];
			[self sendActionsForControlEvents:UIControlEventValueChanged];
            [self.scrollView setContentOffset:CGPointMake(-insets.left, 0) animated:YES];
		}
	} else {
		if (!_refreshing && offset.y <= -(66 + self.defaultContentInsets.top)) {
			_refreshing = YES;
			[self.spinner startAnimating];
			self.arrowView.hidden = YES;
			[UIView beginAnimations:nil context:nil];
			UIEdgeInsets insets = self.scrollView.contentInset;
			insets.top = 88 + self.defaultContentInsets.top;
			self.scrollView.contentInset = insets;
			[UIView commitAnimations];
			[self sendActionsForControlEvents:UIControlEventValueChanged];
            [self.scrollView setContentOffset:CGPointMake(0, -insets.top) animated:YES];
		}
	}
}

- (void)endRefreshing {
	[self performSelector:@selector(endRefreshingAfterDelay) withObject:nil afterDelay:0.2f];
}

- (void)endRefreshingAfterDelay {
	_refreshing = NO;
    [UIView beginAnimations:nil context:nil];
    UIEdgeInsets insets = self.scrollView.contentInset;
    insets.left = self.defaultContentInsets.left;
    insets.top = self.defaultContentInsets.top;
    self.scrollView.contentInset = insets;
    [UIView commitAnimations];
    [self.spinner stopAnimating];
    [self setArrowViewRotated:NO animated:NO];
    self.arrowView.hidden = NO;
}

- (void)refresh {
	if (self.refreshBlock) {
		self.refreshBlock(self);
	}
}

- (void)setColorScheme:(WLRefresherColorScheme)colorScheme {
	_colorScheme = colorScheme;
	if (colorScheme == WLRefresherColorSchemeOrange) {
		self.arrowView.image = [UIImage imageNamed:@"ic_refresh_arrow_orange"];
		self.backgroundColor = [UIColor whiteColor];
		self.spinner.color = [UIColor WL_orangeColor];
	} else {
		self.arrowView.image = [UIImage imageNamed:@"ic_refresh_arrow_white"];
		self.backgroundColor = [UIColor WL_orangeColor];
		self.spinner.color = [UIColor whiteColor];
	}
}

@end
