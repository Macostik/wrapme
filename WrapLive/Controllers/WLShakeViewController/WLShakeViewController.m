//
//  WLBaseViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 07.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLShakeViewController.h"
#import "UIViewController+Additions.h"

@interface WLShakeViewController ()

@property (weak, nonatomic) UISwipeGestureRecognizer* backSwipeGestureRecognizer;

@end

@implementation WLShakeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (void)didRecognizeShakeGesture {
	if (self.navigationController == [UIApplication sharedApplication].keyWindow.rootViewController) {
		
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
		
		[presentingViewController presentViewController:presentedViewController animated:YES completion:nil];
	}
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
