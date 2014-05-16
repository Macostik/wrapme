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
#import "UILabel+Additions.h"
#import "UIView+Shorthand.h"

static CGFloat WLToastDefaultHeight = 64.0f;
static CGFloat WLToastDefaultSpacing = 100.0f;

@interface WLToast ()

@property (weak, nonatomic) UILabel* messageLabel;
@property (weak, nonatomic) UIImageView* iconView;
@property (readonly, nonatomic) UIWindow* presentingWindow;

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
	self = [super initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, WLToastDefaultHeight)];
	if (self) {
		self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
	}
	return self;
}

- (UILabel *)messageLabel {
	if (!_messageLabel) {
		CGRect labelFrame = CGRectMake(0, 0, self.width - WLToastDefaultSpacing, self.bounds.size.height);
		
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

- (UIImageView *)iconView {
	if (!_iconView) {
		UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_alert"]];
		[self addSubview:iconView];
		_iconView = iconView;
	}
	return _iconView;
}

- (void)setMessage:(NSString *)message {
	self.messageLabel.text = message;
	self.messageLabel.size = [self.messageLabel sizeThatFits:CGSizeMake(self.width - WLToastDefaultSpacing, self.height - 20)];
	self.messageLabel.center = CGPointMake(self.width/2.0f, self.height/2.0f + 10);
	self.iconView.center = CGPointMake(self.messageLabel.x - self.iconView.width/2.0f - 5, self.messageLabel.center.y);
}

- (NSString *)message {
	return self.messageLabel.text;
}

+ (void)showWithMessage:(NSString *)message {
	[[self toast] showWithMessage:message];
}

- (UIWindow *)presentingWindow {
	return [[[UIApplication sharedApplication] windows] firstObject];
}

- (UIViewController *)topViewController {
	UINavigationController *rootController = (id)[self.presentingWindow rootViewController];
	if ([rootController isKindOfClass:[UINavigationController class]]) {
		return [rootController topViewController];
	}
	return rootController;
}

- (void)showWithMessage:(NSString *)message {
	
	if ([[self topViewController] isMemberOfClass:[WLHomeViewController class]]) {
		self.height = 84;
	} else {
		self.height = WLToastDefaultHeight;
	}
	
	self.message = message;
	
	__weak WLToast* selfWeak = self;
	if (self.superview == nil) {
		self.y = -self.height;
		[self.presentingWindow addSubview:self];
		[UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			selfWeak.y = 0;
		} completion:^(BOOL finished) {
		}];
	}
	[WLToast cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(dismiss) withObject:nil afterDelay:3];
}

- (void)dismiss {
	__weak WLToast* selfWeak = self;
	[UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		selfWeak.y = -selfWeak.height;
	} completion:^(BOOL finished) {
		[selfWeak removeFromSuperview];
	}];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[WLToast cancelPreviousPerformRequestsWithTarget:self];
	[self dismiss];
}

@end
