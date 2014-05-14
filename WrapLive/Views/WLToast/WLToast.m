//
//  WLToast.m
//  wrapLive
//
//  Created by Sergey Maximenko on 22.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import "WLToast.h"
#import "UIColor+CustomColors.h"
#import "UIFont+CustomFonts.h"
#import "WLBlocks.h"

#import "WLHomeViewController.h"

@interface WLToast ()

@property (weak, nonatomic) UILabel* messageLabel;

@end

@implementation WLToast

+ (instancetype)toast {
	static WLToast* toast = nil;
	if (!toast) {
		toast = [[self alloc] init];
	}
	return toast;
}

- (id)init {
	self = [super init];
	if (self) {
		self.backgroundColor = [UIColor WL_orangeColor];
	}
	return self;
}

- (UILabel *)messageLabel {
	if (!_messageLabel) {
		CGRect labelFrame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
		
		UILabel* messageLabel = [[UILabel alloc] initWithFrame:labelFrame];
		messageLabel.textColor = [UIColor whiteColor];
		messageLabel.numberOfLines = 0;
		messageLabel.textAlignment = NSTextAlignmentCenter;
		messageLabel.font = [UIFont lightSmallFont];
		[self addSubview:messageLabel];
		messageLabel.backgroundColor = [UIColor clearColor];
		_messageLabel = messageLabel;
	}
	return _messageLabel;
}

- (void)setMessage:(NSString *)message {
	self.messageLabel.text = message;
}

- (NSString *)message {
	return self.messageLabel.text;
}

+ (void)showWithMessage:(NSString *)message {
	[[self toast] showWithMessage:message];
}

- (UIViewController *)topViewController {
	UIWindow * window = [[[UIApplication sharedApplication] windows] firstObject];
	UINavigationController * rootController = (id)[window rootViewController];
	return [rootController topViewController];
}

- (void)showWithMessage:(NSString *)message {
	self.message = message;
	__weak WLToast* selfWeak = self;
	if (self.superview == nil) {
		NSInteger toastHeight = 64;
		if ([[self topViewController] isMemberOfClass:[WLHomeViewController class]]) {
			toastHeight = 84;
		}
		self.frame = CGRectMake(0, -toastHeight, [UIScreen mainScreen].bounds.size.width, toastHeight);
		self.messageLabel.frame = CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, toastHeight - 20);
		[[[[UIApplication sharedApplication] windows] firstObject] addSubview:self];
		[UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			selfWeak.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, toastHeight);
		} completion:^(BOOL finished) {
		}];
	}
	
	[WLToast cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(dismiss) withObject:nil afterDelay:3];
}

- (void)dismiss {
	__weak WLToast* selfWeak = self;
	[UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		selfWeak.frame = CGRectMake(0, -44, [UIScreen mainScreen].bounds.size.width, 44);
	} completion:^(BOOL finished) {
		[selfWeak removeFromSuperview];
	}];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[WLToast cancelPreviousPerformRequestsWithTarget:self];
	[self dismiss];
}

@end
