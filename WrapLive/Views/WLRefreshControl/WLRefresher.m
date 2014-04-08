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

static NSString* WlRefresherContentOffsetKeyPath = @"contentOffset";

@interface WLRefresher ()

@property (readonly, nonatomic) UIScrollView* scrollView;
@property (nonatomic) WLRefresherScrollDirection direction;
@property (strong, nonatomic) void (^refreshBlock) (WLRefresher *);
@property (weak, nonatomic) UIActivityIndicatorView* spinner;
@property (weak, nonatomic) UIImageView* arrowView;

@end

@implementation WLRefresher
{
	BOOL _refreshing;
}

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

+(WLRefresher *)refresherWithScrollView:(UIScrollView *)scrollView refreshBlock:(void (^)(WLRefresher *))refreshBlock {
	WLRefresher* refresher = [self refresherWithScrollView:scrollView];
	refresher.refreshBlock = refreshBlock;
	[refresher addTarget:refresher action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
	return refresher;
}

+ (WLRefresher*)refresherWithScrollView:(UIScrollView *)scrollView {
	WLRefresherScrollDirection direction = scrollView.frame.size.height > scrollView.frame.size.width ? WLRefresherScrollDirectionVertical : WLRefresherScrollDirectionHorizontal;
	return [self refresherWithScrollView:scrollView direction:direction];
}

+ (WLRefresher*)refresherWithScrollView:(UIScrollView *)scrollView direction:(WLRefresherScrollDirection)direction {
	CGRect frame;
	CGPoint spinnerCenter;
	if (direction == WLRefresherScrollDirectionHorizontal) {
		frame = CGRectMake(-scrollView.frame.size.width, 0, scrollView.frame.size.width, scrollView.frame.size.height);
		spinnerCenter = CGPointMake(scrollView.frame.size.width - 44, scrollView.frame.size.height/2);
	} else {
		frame = CGRectMake(0, -scrollView.frame.size.height, scrollView.frame.size.width, scrollView.frame.size.height);
		spinnerCenter = CGPointMake(scrollView.frame.size.width/2, scrollView.frame.size.height - 44);
	}
	WLRefresher* refresher = [[WLRefresher alloc] initWithFrame:frame];
	refresher.direction = direction;
	refresher.backgroundColor = [UIColor WL_orangeColor];
	[scrollView addSubview:refresher];
	refresher.spinner.center = spinnerCenter;
	refresher.arrowView.center = spinnerCenter;
	return refresher;
}

- (UIActivityIndicatorView *)spinner {
	if (!_spinner) {
		UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		spinner.hidesWhenStopped = YES;
		[self addSubview:spinner];
		_spinner = spinner;
	}
	return _spinner;
}

- (UIImageView *)arrowView {
	if (!_arrowView) {
		UIImageView* arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_refresh_arrow"]];
		[self addSubview:arrowView];
		_arrowView = arrowView;
	}
	return _arrowView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (keyPath == WlRefresherContentOffsetKeyPath) {
		[self didChangeContentOffset:self.scrollView.contentOffset];
	}
}

- (void)didChangeContentOffset:(CGPoint)offset {
	if (self.direction == WLRefresherScrollDirectionHorizontal) {
		if (offset.x < 0) {
			[self setArrowViewRotated:(offset.x <= -66) animated:YES];
			if (!self.scrollView.dragging) {
				[self didEndDragging:self.scrollView.contentOffset];
			}
		}
	} else {
		if (offset.y < 0) {
			[self setArrowViewRotated:(offset.y <= -66) animated:YES];
			if (!self.scrollView.dragging) {
				[self didEndDragging:self.scrollView.contentOffset];
			}
		}
	}
}

- (void)setArrowViewRotated:(BOOL)rotated animated:(BOOL)animated {
	
	CGAffineTransform transform;
	
	if (self.direction == WLRefresherScrollDirectionHorizontal) {
		transform = CGAffineTransformMakeRotation(rotated ? (M_PI_2 + M_PI) : M_PI_2);
	} else {
		transform = CGAffineTransformMakeRotation(rotated ? 2*M_PI : M_PI);
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
		if (!_refreshing && offset.x <= -66) {
			_refreshing = YES;
			[self.spinner startAnimating];
			self.arrowView.hidden = YES;
			[UIView beginAnimations:nil context:nil];
			self.scrollView.contentInset = UIEdgeInsetsMake(0, 88, 0, 0);
			self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 88, 0, 0);
			[UIView commitAnimations];
			[self sendActionsForControlEvents:UIControlEventValueChanged];
		}
	} else {
		if (!_refreshing && offset.y <= -66) {
			_refreshing = YES;
			[self.spinner startAnimating];
			self.arrowView.hidden = YES;
			[UIView beginAnimations:nil context:nil];
			self.scrollView.contentInset = UIEdgeInsetsMake(88, 0, 0, 0);
			self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(88, 0, 0, 0);
			[UIView commitAnimations];
			[self sendActionsForControlEvents:UIControlEventValueChanged];
		}
	}
}

- (void)endRefreshing {
	_refreshing = NO;
	[UIView beginAnimations:nil context:nil];
	self.scrollView.contentInset = UIEdgeInsetsZero;
	self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
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
