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
#import "UILabel+Additions.h"
#import "UIView+Shorthand.h"
#import "WLSupportFunctions.h"

static CGFloat WLToastDefaultHeight = 64.0f;
static CGFloat WLToastDefaultSpacing = 100.0f;

@interface WLToast ()

@property (weak, nonatomic) UILabel* messageLabel;
@property (weak, nonatomic) UIImageView* iconView;

@end

@implementation WLToast

+ (instancetype)toast {
	static WLToast* toast = nil;
	if (!toast) {
		toast = [[self alloc] init];
	}
	return toast;
}

+ (void)showWithMessage:(NSString *)message {
	[[self toast] showWithMessage:message];
}

+ (void)showWithMessage:(NSString *)message appearance:(id<WLToastAppearance>)appearance {
	[[self toast] showWithMessage:message appearance:appearance];
}

- (void)showWithMessage:(NSString *)message {
	[self showWithMessage:message appearance:TopViewController()];
}

- (void)showWithMessage:(NSString *)message appearance:(id<WLToastAppearance>)appearance {
	
	self.height = appearance ? [appearance toastAppearanceHeight:self] : WLToastDefaultHeight;
	
	self.message = message;
	
	if (self.messageLabel.height > self.height - 20) {
		self.height = self.messageLabel.height + 40;
		self.messageLabel.y = 30;
	}
	
	if (self.superview == nil) {
		self.y = -self.height;
		[MainWindow() addSubview:self];
	}
	
	if (self.y != 0) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25f];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		self.y = 0;
		[UIView commitAnimations];
	}
	
	[WLToast cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
	[WLToast cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeFromSuperview) object:nil];
	[self performSelector:@selector(dismiss) withObject:nil afterDelay:3];
}

- (void)dismiss {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.25f];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	self.y = -self.height;
	[UIView commitAnimations];
	[self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:5];
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[WLToast cancelPreviousPerformRequestsWithTarget:self];
	[self dismiss];
}

@end

@implementation UIViewController (WLToast)

- (CGFloat)toastAppearanceHeight:(WLToast *)toast {
	return WLToastDefaultHeight;
}

@end
