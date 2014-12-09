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
#import "WLTelephony.h"

@interface WLShakeViewController ()

@end

@implementation WLShakeViewController

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

    if ([WLTelephony isCallingNow]) {
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

@end
