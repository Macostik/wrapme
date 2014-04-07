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

@interface WLRefresher ()

@property (weak, nonatomic) UIScrollView* scrollView;
@property (nonatomic) WLRefresherScrollDirection direction;
@property (strong, nonatomic) void (^refreshBlock) (WLRefresher *);
@property (weak, nonatomic) UIActivityIndicatorView* spinner;

@end

@implementation WLRefresher
{
	BOOL _refreshing;
}

static NSString* WlRefresherContentOffsetKeyPath = @"contentOffset";
static NSString* WlRefresherPanningStateKeyPath = @"panGestureRecognizer.state";

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
	refresher.scrollView = scrollView;
	refresher.backgroundColor = [UIColor WL_orangeColor];
	[scrollView addObserver:refresher forKeyPath:WlRefresherContentOffsetKeyPath options:NSKeyValueObservingOptionNew context:NULL];
	[scrollView addObserver:refresher forKeyPath:WlRefresherPanningStateKeyPath options:NSKeyValueObservingOptionNew context:NULL];
	[scrollView addSubview:refresher];
	refresher.spinner.center = spinnerCenter;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (keyPath == WlRefresherContentOffsetKeyPath) {
		[self didChangeContentOffset:self.scrollView.contentOffset];
	} else if (keyPath == WlRefresherPanningStateKeyPath) {
		if (self.scrollView.panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
			[self didEndDragging:self.scrollView.contentOffset];
		}
	}
}

- (void)didChangeContentOffset:(CGPoint)offset {
	if (self.direction == WLRefresherScrollDirectionHorizontal) {
		if (offset.x < 0) {
			self.alpha = Smoothstep(0, 1, ABS(offset.x/88));
		}
	} else {
		if (offset.y < 0) {
			self.alpha = Smoothstep(0, 1, ABS(offset.y/88));
		}
	}
}

- (void)didEndDragging:(CGPoint)offset {
	
	if (self.direction == WLRefresherScrollDirectionHorizontal) {
		if (!_refreshing && offset.x < -66) {
			_refreshing = YES;
			[self.spinner startAnimating];
			[UIView beginAnimations:nil context:nil];
			self.scrollView.contentInset = UIEdgeInsetsMake(0, 88, 0, 0);
			[UIView commitAnimations];
			[self sendActionsForControlEvents:UIControlEventValueChanged];
		}
	} else {
		if (!_refreshing && offset.y < -66) {
			_refreshing = YES;
			[self.spinner startAnimating];
			[UIView beginAnimations:nil context:nil];
			self.scrollView.contentInset = UIEdgeInsetsMake(88, 0, 0, 0);
			[UIView commitAnimations];
			[self sendActionsForControlEvents:UIControlEventValueChanged];
		}
	}
}

- (void)endRefreshing {
	_refreshing = NO;
	[UIView beginAnimations:nil context:nil];
	self.scrollView.contentInset = UIEdgeInsetsZero;
	[UIView commitAnimations];
	[self.spinner stopAnimating];
}

- (void)refresh {
	if (self.refreshBlock) {
		self.refreshBlock(self);
	}
}

@end
