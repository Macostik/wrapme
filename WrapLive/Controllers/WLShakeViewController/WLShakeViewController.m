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
#import "WLNavigation.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

static CTCallCenter *callCenter;

@interface WLShakeViewController ()

@property (weak, nonatomic) UISwipeGestureRecognizer* backSwipeGestureRecognizer;

@property (nonatomic, readonly) BOOL isCalling;

@end

@implementation WLShakeViewController

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)setIsShowPlaceholder:(BOOL)isShowPlaceholder {
    if (_isShowPlaceholder != isShowPlaceholder) {
        _isShowPlaceholder = isShowPlaceholder;
        if (isShowPlaceholder) {
            [self showPlaceholder];
        } else {
            [self.noContentPlaceholder removeFromSuperview];
            [self.titleNoContentPlaceholder removeFromSuperview];
        }
    }
}

- (void)showPlaceholder {
    self.noContentPlaceholder = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"notContentPlaceholder"]];
    self.noContentPlaceholder.center = CGPointMake(self.view.center.x, self.view.center.y + 40) ;
    [self.view insertSubview:self.noContentPlaceholder atIndex:0];
}

- (BOOL)isCalling {
    CTCallCenter *callCenter = [[CTCallCenter alloc] init];
    for (CTCall* call in callCenter.currentCalls) {
        if ([call.callState matches:CTCallStateConnected, CTCallStateIncoming, nil]) {
            return YES;
        }
    }
    return NO;
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
    if (event.subtype == UIEventSubtypeMotionShake) {
        [self didRecognizeShakeGesture];
    }
    [super motionEnded:motion withEvent:event];
}

- (BOOL)canBecomeFirstRehaonder {
	return YES;
}

- (UIViewController *)shakePresentedViewController {
	return nil;
}

- (BOOL)didRecognizeShakeGesture {

    if (self.isCalling) {
        return NO;
    }
    
	UINavigationController* rootNavigationController = (id)[UIApplication sharedApplication].keyWindow.rootViewController;
	if (self.navigationController == rootNavigationController) {
		if ([self.childViewControllers count] == 0 && self.parentViewController.navigationController != rootNavigationController) {
			return [self presentShakeViewController];
		}
	}
	
	if (self.presentingViewController == rootNavigationController) {
		__weak typeof(self)weakSelf = self;
		[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
			[weakSelf presentShakeViewControllerWithNavigationController:rootNavigationController];
		}];
		return YES;
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

- (BOOL)presentShakeViewControllerWithNavigationController:(UINavigationController*)navigationController {
	WLShakeViewController* presentingViewController = nil;
	UIViewController* presentedViewController = nil;
	
	NSEnumerator* enumerator = [navigationController.viewControllers reverseObjectEnumerator];
	for (WLShakeViewController* viewController in enumerator) {
		if ([viewController isKindOfClass:[WLShakeViewController class]]) {
			presentedViewController = [viewController shakePresentedViewController];
			if (presentedViewController) {
				presentingViewController = viewController;
				break;
			}
		}
	}
	
	if (presentingViewController && presentingViewController != navigationController.topViewController) {
		run_after(0.5f, ^{
			[navigationController popToViewController:presentingViewController animated:NO];
		});
	}
	
	if (presentingViewController && presentedViewController) {
		[presentingViewController.navigationController presentViewController:presentedViewController animated:YES completion:nil];
		return YES;
	}
	return NO;

}

- (BOOL)presentShakeViewController {
	return [self presentShakeViewControllerWithNavigationController:self.navigationController];
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
