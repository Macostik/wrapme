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
#import "UILabel+Additions.h"
#import "UIView+Shorthand.h"
#import "WLNavigation.h"
#import "UIImage+Drawing.h"
#import "WLLabel.h"

static CGFloat WLToastDefaultHeight = 64.0f;
static CGFloat WLToastDefaultSpacing = 100.0f;

@implementation WLToastAppearance

+ (instancetype)appearance {
	return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.height = WLToastDefaultHeight;
		self.shouldShowIcon = YES;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
        self.textColor = [UIColor whiteColor];
        self.contentMode = UIViewContentModeBottom;
        self.startY = -self.height;
    }
    return self;
}

#pragma mark - WLToastAppearance

- (CGFloat)toastAppearanceHeight:(WLToast *)toast {
	return self.height;
}

- (BOOL)toastAppearanceShouldShowIcon:(WLToast *)toast {
	return self.shouldShowIcon;
}

- (UIColor*)toastAppearanceBackgroundColor:(WLToast*)toast {
    return self.backgroundColor;
}

- (UIColor*)toastAppearanceTextColor:(WLToast*)toast {
    return self.textColor;
}

- (UIViewContentMode)toastAppearanceContentMode:(WLToast *)toast {
    return self.contentMode;
}

- (CGFloat)toastAppearanceStartY:(WLToast *)toast {
    return self.startY;
}

- (CGFloat)toastAppearanceEndY:(WLToast *)toast {
    return self.endY;
}

@end

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

+ (void)showWithMessage:(NSString *)message appearance:(id<WLToastAppearance>)appearance inView:(UIView *)view {
	[[self toast] showWithMessage:message appearance:appearance inView:view];
}

- (void)showWithMessage:(NSString *)message {
	[self showWithMessage:message appearance:[UINavigationController topViewController]];
}

- (void)showWithMessage:(NSString *)message appearance:(id<WLToastAppearance>)appearance {
    UIViewController *rootViewController = [UIWindow mainWindow].rootViewController;
    [self showWithMessage:message appearance:appearance inView:rootViewController.presentedViewController ? rootViewController.presentedViewController.view : rootViewController.view];
}

- (void)showWithMessage:(NSString *)message appearance:(id<WLToastAppearance>)appearance inView:(UIView *)view {
    
    [self setFullFlexible];
    
	self.height = [appearance respondsToSelector:@selector(toastAppearanceHeight:)] ? [appearance toastAppearanceHeight:self] : WLToastDefaultHeight;
	
	self.iconView.hidden = [appearance respondsToSelector:@selector(toastAppearanceShouldShowIcon:)] ? ![appearance toastAppearanceShouldShowIcon:self] : YES;
    
    if ([appearance respondsToSelector:@selector(toastAppearanceBackgroundColor:)]) {
        self.backgroundColor = [appearance toastAppearanceBackgroundColor:self];
    } else {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
    }
    
    if ([appearance respondsToSelector:@selector(toastAppearanceTextColor:)]) {
        self.messageLabel.textColor = [appearance toastAppearanceTextColor:self];
    } else {
        self.messageLabel.textColor = [UIColor whiteColor];
    }
	
	self.message = message;
	
	if (self.messageLabel.height > self.height - 20) {
		self.height = self.messageLabel.height + 40;
        self.messageLabel.y = 30;
	}
    
    UIViewContentMode contentMode = UIViewContentModeBottom;
    if ([appearance respondsToSelector:@selector(toastAppearanceContentMode:)]) {
        contentMode = [appearance toastAppearanceContentMode:self];
    }
    
    if (contentMode == UIViewContentModeCenter) {
        self.messageLabel.y = self.height/2 - self.messageLabel.height/2;
    }
	
    CGFloat startY = -self.height;
    
    if ([appearance respondsToSelector:@selector(toastAppearanceStartY:)]) {
        startY = [appearance toastAppearanceStartY:self];
    }
    
	if (self.superview == nil) {
		self.y = startY;
		[view addSubview:self];
	}
	
    CGFloat endY = 0;
    
    if ([appearance respondsToSelector:@selector(toastAppearanceEndY:)]) {
        endY = [appearance toastAppearanceEndY:self];
    }
    
	if (self.y != endY || self.alpha != 1.0f) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25f];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		self.y = endY;
        self.alpha = 1.0f;
		[UIView commitAnimations];
	}
	[WLToast cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
	[WLToast cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeFromSuperview) object:nil];
	[self performSelector:@selector(dismiss) withObject:nil afterDelay:WLToastDismissalDelay];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    self.alpha = 0.0f;
}

- (void)dismiss {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.25f];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    if (self.y == 0) {
        self.y = -self.height;
    } else {
        self.alpha = 0.0f;
    }
	[UIView commitAnimations];
	[self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:5];
}

- (id)init {
	self = [super initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, WLToastDefaultHeight)];
	if (self) {
		self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
        self.alpha = 0.0f;
	}
	return self;
}

- (UILabel *)messageLabel {
	if (!_messageLabel) {
		CGRect labelFrame = CGRectMake(0, 0, self.width - WLToastDefaultSpacing, self.bounds.size.height);
		
		WLLabel* messageLabel = [[WLLabel alloc] initWithFrame:labelFrame];
		messageLabel.textColor = [UIColor whiteColor];
		messageLabel.numberOfLines = 0;
		messageLabel.textAlignment = NSTextAlignmentCenter;
		messageLabel.font = [UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetSmall];
        messageLabel.preset = WLFontPresetSmall;
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

- (BOOL)toastAppearanceShouldShowIcon:(WLToast *)toast {
	return YES;
}

@end

@implementation WLToast (DefinedToasts)

+ (void)showPhotoDownloadingMessage {
    WLToastAppearance *appearance = [[WLToastAppearance alloc] init];
    appearance.shouldShowIcon = NO;
    [self showWithMessage:[NSString stringWithFormat:WLLS(@"Downloading the photo now. It will be in \"%@\" album momentarily."), WLAlbumName] appearance:appearance];
}

@end
