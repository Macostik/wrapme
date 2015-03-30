//
//  WLToast.m
//  wrapLive
//
//  Created by Sergey Maximenko on 22.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import "WLToast.h"
#import "UIFont+CustomFonts.h"
#import "UILabel+Additions.h"
#import "UIView+Shorthand.h"
#import "WLNavigation.h"
#import "WLLabel.h"
#import "NSObject+NibAdditions.h"
#import "UIView+AnimationHelper.h"

@implementation WLToastAppearance

+ (instancetype)appearance {
	return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
		self.shouldShowIcon = YES;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
        self.textColor = [UIColor whiteColor];
        self.contentMode = UIViewContentModeBottom;
    }
    return self;
}

#pragma mark - WLToastAppearance

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

@end

@interface WLToast ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel* messageLabel;
@property (weak, nonatomic) IBOutlet UIImageView* iconView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewConstraint;

@end

@implementation WLToast

+ (instancetype)toast {
    static WLToast* toast = nil;
    if (!toast) {
        toast = [self loadFromNib];
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
	
	self.iconView.hidden = [appearance respondsToSelector:@selector(toastAppearanceShouldShowIcon:)] ? ![appearance toastAppearanceShouldShowIcon:self] : YES;
    
    if ([appearance respondsToSelector:@selector(toastAppearanceBackgroundColor:)]) {
        self.contentView.backgroundColor = [appearance toastAppearanceBackgroundColor:self];
    }
    
    if ([appearance respondsToSelector:@selector(toastAppearanceTextColor:)]) {
        self.messageLabel.textColor = [appearance toastAppearanceTextColor:self];
    }
    
    self.messageLabel.text = message;
    
    UIViewContentMode contentMode = UIViewContentModeBottom;
    if ([appearance respondsToSelector:@selector(toastAppearanceContentMode:)]) {
        contentMode = [appearance toastAppearanceContentMode:self];
    }
    
	if (self.superview == nil) {
        self.frame = view.bounds;
        [self setFullFlexible];
		[view addSubview:self];
    }
    
    if (self.topViewConstraint.constant != .0) {
        [UIView performAnimated:YES animation:^{
            self.topViewConstraint.constant = .0;
            [self.contentView layoutIfNeeded];
        }];
    }
    
	[WLToast cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
	[WLToast cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeFromSuperview) object:nil];
	[self performSelector:@selector(dismiss) withObject:nil afterDelay:WLToastDismissalDelay];
}

- (void)dismiss {
    if (self.topViewConstraint.constant == 0) {
        [UIView animateWithDuration:.25 animations:^{
            self.topViewConstraint.constant = -self.contentView.height;
            [self.contentView layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(self.contentView.bounds, point)) {
        [WLToast cancelPreviousPerformRequestsWithTarget:self];
        [self dismiss];
        return YES;
    }
    return NO;
}

@end

@implementation UIViewController (WLToast)

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
