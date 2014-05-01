//
//  WLBaseViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 07.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLShakeViewController.h"
#import "UIViewController+Additions.h"
#import "UIView+Shorthand.h"

@interface WLShakeViewController ()

@property (nonatomic) WLWrapTransition transition;

@property (weak, nonatomic) UISwipeGestureRecognizer* backSwipeGestureRecognizer;

@property (nonatomic, strong) UIView* translucentView;

@end

@implementation WLShakeViewController

- (void)presentInViewController:(UIViewController *)controller transition:(WLWrapTransition)transition completion:(void (^)(void))completion {
	self.transition = transition;
	self.view.frame = controller.view.bounds;
	[controller.view addSubview:self.view];
	[controller addChildViewController:self];
	BOOL animated = transition != WLWrapTransitionWithoutAnimation;
	[controller viewWillDisappear:animated];
	if (animated) {
		__weak typeof(self)weakSelf = self;
		if (transition == WLWrapTransitionFromBottom) {
			self.view.transform = CGAffineTransformMakeTranslation(0, self.view.height);
		} else if (transition == WLWrapTransitionFromRight) {
			self.view.transform = CGAffineTransformMakeTranslation(self.view.width, 0);
		}
		[UIView animateWithDuration:0.33f
							  delay:0.0f
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^{
							 weakSelf.view.transform = CGAffineTransformIdentity;
						 } completion:^(BOOL finished) {
							 [weakSelf didMoveToParentViewController:controller];
							 [controller viewDidDisappear:animated];
							 if (completion) {
								 completion();
							 }
						 }];
	} else {
		[self didMoveToParentViewController:controller];
		[controller viewDidDisappear:animated];
		if (completion) {
			completion();
		}
	}
}

- (void)presentInViewController:(UIViewController *)controller transition:(WLWrapTransition)transition {
	[self presentInViewController:controller transition:transition completion:nil];
}

- (void)dismiss:(WLWrapTransition)transition completion:(void (^)(void))completion {
	[self willMoveToParentViewController:nil];
	BOOL animated = transition != WLWrapTransitionWithoutAnimation;
	[self.parentViewController viewWillAppear:animated];
	if (animated) {
		__weak typeof(self)weakSelf = self;
		
		void (^animationBlock)(void) = nil;
		
		if (transition == WLWrapTransitionFromBottom) {
			animationBlock = ^{
				weakSelf.view.transform = CGAffineTransformMakeTranslation(0, weakSelf.view.height);
			};
		} else if (transition == WLWrapTransitionFromRight) {
			animationBlock = ^{
				weakSelf.view.transform = CGAffineTransformMakeTranslation(weakSelf.view.width, 0);
			};
		}
		
		[UIView animateWithDuration:0.33f
							  delay:0.0f
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:animationBlock
						 completion:^(BOOL finished) {
							 [weakSelf.view removeFromSuperview];
							 [weakSelf removeFromParentViewController];
							 [weakSelf.parentViewController viewDidAppear:animated];
							 if (completion) {
								 completion();
							 }
						 }];
	} else {
		[self.view removeFromSuperview];
		[self removeFromParentViewController];
		[self.parentViewController viewDidAppear:animated];
		if (completion) {
			completion();
		}
	}
}

- (void)dismiss:(WLWrapTransition)transition {
	[self dismiss:transition completion:nil];
}

- (void)dismiss {
	[self dismiss:self.transition];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (UIView *)translucentView {
	if (!_translucentView) {
		UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:self.view.bounds];
		toolbar.tintColor = [UIColor whiteColor];
		toolbar.translucent = YES;
		_translucentView = toolbar;
	}
	return _translucentView;
}

- (void)setTranslucent {
	self.view.backgroundColor = [UIColor clearColor];
	[self.view insertSubview:self.translucentView atIndex:0];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if ( event.subtype == UIEventSubtypeMotionShake ) {
        [self didRecognizeShakeGesture];
    }
    [super motionEnded:motion withEvent:event];
}

- (UIViewController *)shakePresentedViewController {
	return nil;
}

- (BOOL)didRecognizeShakeGesture {
	UINavigationController* rootNavigationController = (id)[UIApplication sharedApplication].keyWindow.rootViewController;
	if (self.navigationController == rootNavigationController) {
		if ([self.childViewControllers count] == 0 && self.parentViewController.navigationController != rootNavigationController) {
			return [self presentShakeViewController];
		}
	}
	WLShakeViewController* presentingViewController = (id)self.presentingViewController;
	if (presentingViewController.navigationController == rootNavigationController) {
		if ([presentingViewController isKindOfClass:[WLShakeViewController class]]) {
			[presentingViewController dismissViewControllerAnimated:YES completion:^{
				[presentingViewController presentShakeViewController];
			}];
			return YES;
		}
	}
	return NO;
}

- (BOOL)presentShakeViewController {
	WLShakeViewController* presentingViewController = nil;
	UIViewController* presentedViewController = nil;
	
	NSEnumerator* enumerator = [self.navigationController.viewControllers reverseObjectEnumerator];
	for (WLShakeViewController* viewController in enumerator) {
		if ([viewController isKindOfClass:[WLShakeViewController class]]) {
			presentedViewController = [viewController shakePresentedViewController];
			if (presentedViewController) {
				presentingViewController = viewController;
				break;
			}
		}
	}
	
	if (presentingViewController && presentingViewController != self.navigationController.topViewController) {
		[self.navigationController popToViewController:presentingViewController animated:NO];
	}
	
	if (presentingViewController && presentedViewController) {
		[presentingViewController presentViewController:presentedViewController animated:YES completion:nil];
		return YES;
	}
	return NO;
}

- (void)setBackSwipeGestureEnabled:(BOOL)backSwipeGestureEnabled {
	if (backSwipeGestureEnabled) {
		UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(backSwipeGesture)];
		recognizer.direction = UISwipeGestureRecognizerDirectionRight;
		[self.view addGestureRecognizer:recognizer];
		self.backSwipeGestureRecognizer = recognizer;
	} else if (self.backSwipeGestureRecognizer) {
		[self.view removeGestureRecognizer:self.backSwipeGestureRecognizer];
		self.backSwipeGestureRecognizer = nil;
	}
}

- (BOOL)backSwipeGestureEnabled {
	return (self.backSwipeGestureRecognizer != nil);
}

- (void)backSwipeGesture {
	if (self.isOnTopOfNagvigation) {
		self.backSwipeGestureEnabled = NO;
		[self.navigationController popViewControllerAnimated:YES];
	}
}

@end
