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
#import "WLNavigation.h"
#import "WLLabel.h"
#import "NSObject+NibAdditions.h"
#import "UIView+AnimationHelper.h"
#import "WLNavigation.h"

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

@implementation WLToast

+ (instancetype)toast {
    static WLToast *toast = nil;
    if (!toast) {
        toast = [self new];
    }
    return toast;
}

+ (void)showWithMessage:(NSString *)message {
    [WLToast showWithMessage:message appearance:[WLToastAppearance appearance]];
}

+ (void)showWithMessage:(NSString *)message appearance:(id<WLToastAppearance>)appearance {
    [[WLToast toast] showWithMessage:message appearance:appearance];
}

- (void)showWithMessage:(NSString *)message appearance:(id<WLToastAppearance>)appearance {
    [WLToastViewController setMessage:message withAppearance:appearance];
}

@end

@implementation WLToastWindow

static WLToastWindow *sharedWindow = nil;

+ (WLToastWindow *)sharedWindow {
    if (!sharedWindow) {
        sharedWindow = [[WLToastWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        sharedWindow.windowLevel = UIWindowLevelAlert;
        sharedWindow.hidden = NO;
        didReceiveMemoryWarning(^{
            sharedWindow = nil;
        });
    }
    return sharedWindow;
}

- (void)setViewControllerAsRoot {
    sharedWindow.rootViewController = [[WLToastViewController alloc] initWithNibName:@"WLToast" bundle:nil];
    [sharedWindow makeKeyAndVisible];
    [WLToastWindow cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:WLToastDismissalDelay];
}

- (id)toastAsRootViewController {
    return sharedWindow.rootViewController;
}

- (void)dismiss {
    [[self toastAsRootViewController] dismissWithComplition:^(BOOL finished) {
        sharedWindow = nil;
        [[UIWindow mainWindow] makeKeyAndVisible];
    }];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint([[self toastAsRootViewController] contentView].bounds, point)) {
        [WLToastWindow cancelPreviousPerformRequestsWithTarget:self];
        [sharedWindow dismiss];
        return YES;
    }
    return NO;
}

@end

@interface WLToastViewController ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel* messageLabel;
@property (weak, nonatomic) IBOutlet UIImageView* iconView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewConstraint;

@end

@implementation WLToastViewController

+ (void)setMessage:(NSString *)message withAppearance:(id<WLToastAppearance>)appearance {
    [[WLToastWindow sharedWindow] setViewControllerAsRoot];
    [sharedWindow.toastAsRootViewController setMessage:message withAppearance:appearance];
}

- (void)setMessage:(NSString *)message withAppearance:(id<WLToastAppearance>)appearance {
    
    self.iconView.hidden = [appearance respondsToSelector:@selector(toastAppearanceShouldShowIcon:)] ? ![appearance toastAppearanceShouldShowIcon:[WLToast toast]] : YES;
    
    if ([appearance respondsToSelector:@selector(toastAppearanceBackgroundColor:)]) {
        self.contentView.backgroundColor = [appearance toastAppearanceBackgroundColor:[WLToast toast]];
    }
    
    if ([appearance respondsToSelector:@selector(toastAppearanceTextColor:)]) {
        self.messageLabel.textColor = [appearance toastAppearanceTextColor:[WLToast toast]];
    }
    
    self.messageLabel.text = message;
    
    UIViewContentMode contentMode = UIViewContentModeBottom;
    if ([appearance respondsToSelector:@selector(toastAppearanceContentMode:)]) {
        contentMode = [appearance toastAppearanceContentMode:[WLToast toast]];
    }
    
    if (self.topViewConstraint.constant != .0) {
        [UIView performAnimated:YES animation:^{
            self.topViewConstraint.constant = .0;
            [self.contentView layoutIfNeeded];
        }];
    }
}

- (void)dismissWithComplition:(void (^)(BOOL finished))completion {
    if (self.topViewConstraint.constant == 0) {
        [UIView animateWithDuration:.25 animations:^{
            self.topViewConstraint.constant = -self.contentView.height;
            [self.contentView layoutIfNeeded];
        } completion:completion];
    }
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (NSUInteger)supportedInterfaceOrientations {
    return  UIInterfaceOrientationMaskAll;
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
    [WLToastViewController setMessage:[NSString stringWithFormat:WLLS(@"Downloading the photo now. It will be in \"%@\" album momentarily."), WLAlbumName] withAppearance:appearance];
}

@end
