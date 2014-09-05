//
//  UIViewController+PGNavigationBack.m
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 6/14/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "UIViewController+Additions.h"

@implementation UIViewController (Additions)

- (BOOL)isOnTopOfNagvigation {
	return self.navigationController.topViewController == self;
}

- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated {
	if ([self isOnTopOfNagvigation]) {
		[self.navigationController pushViewController:controller animated:animated];
	}
}

- (void)pushViewControllerNextToCurrent:(UIViewController*)controller animated:(BOOL)animated {
	[self pushViewController:controller nextToViewController:self animated:animated];
}

- (void)pushViewControllerNextToRootViewController:(UIViewController *)controller animated:(BOOL)animated {
	[self pushViewController:controller nextToViewController:[self.navigationController.viewControllers firstObject] animated:animated];
}

- (void)pushViewController:(UIViewController *)controller
	  nextToViewController:(UIViewController *)nextToController
				  animated:(BOOL)animated {
	NSMutableArray* controllers = [NSMutableArray array];
	
	for (UIViewController* ctrlr in self.navigationController.viewControllers) {
		[controllers addObject:ctrlr];
		if (ctrlr == nextToController) {
			[controllers addObject:controller];
			break;
		}
	}
	
	[self.navigationController setViewControllers:[NSArray arrayWithArray:controllers] animated:animated];
}

- (IBAction)back:(UIButton *)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

@end
