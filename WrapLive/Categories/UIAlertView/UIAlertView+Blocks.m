//
//  UIAlertView+Blocks.m
//  WrapLive
//
//  Created by Sergey Maximenko on 05.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIAlertView+Blocks.h"
#import <objc/runtime.h>
#import "NSObject+AssociatedObjects.h"

@interface UIAlertView () <UIAlertViewDelegate>

@end

@implementation UIAlertView (Blocks)

+ (void)showWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completion:(WLAlertViewCompletion)completion {
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
	alertView.cancelButtonIndex = -1;
	for (NSString* button in buttons) {
		[alertView addButtonWithTitle:button];
	}
	alertView.completion = completion;
	[alertView show];
}

+ (void)showWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel action:(NSString *)action completion:(void (^)(void))completion {
	[self showWithTitle:title message:message buttons:@[cancel, action] completion:^(NSUInteger index) {
		if (index == 1 && completion) {
			completion();
		}
	}];
}

+ (void)showWithTitle:(NSString *)title message:(NSString *)message action:(NSString *)action cancel:(NSString *)cancel completion:(void (^)(void))completion {
	[self showWithTitle:title message:message buttons:@[action, cancel] completion:^(NSUInteger index) {
		if (index == 0 && completion) {
			completion();
		}
	}];
}

- (WLAlertViewCompletion)completion {
	return [self associatedObjectForKey:"wl_alertview_completion"];
}

- (void)setCompletion:(WLAlertViewCompletion)completion {
	self.delegate = self;
	[self setAssociatedObject:completion forKey:"wl_alertview_completion"];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	WLAlertViewCompletion completion = self.completion;
	if (completion) {
		completion(buttonIndex);
	}
}

@end
