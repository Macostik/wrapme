//
//  WLToast.m
//  meWrap
//
//  Created by Ravenpod on 22.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import "WLToast.h"
#import "WLNavigationHelper.h"
#import "WLLabel.h"
#import "NSObject+NibAdditions.h"
#import "WLNavigationHelper.h"
#import "UIColor+CustomColors.h"

@implementation WLToastAppearance

+ (instancetype)defaultAppearance {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
		self.shouldShowIcon = YES;
        self.backgroundColor = [UIColor colorWithHexString:@"#CB5309"];
        self.textColor = [UIColor whiteColor];
    }
    return self;
}

#pragma mark - WLToastAppearance

- (BOOL)toastAppearanceShouldShowIcon:(WLToast *)toast {
	return self.shouldShowIcon;
}

- (UIColor*)toastAppearanceBackgroundColor:(WLToast *)toast {
    return self.backgroundColor;
}

- (UIColor*)toastAppearanceTextColor:(WLToast *)toast {
    return self.textColor;
}

@end

@interface WLToast ()

@property (weak, nonatomic) IBOutlet UILabel* messageLabel;

@property (weak, nonatomic) IBOutlet UIView* iconView;

@property (weak, nonatomic) NSLayoutConstraint *topViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topMessageInset;

@property (strong, nonatomic) WLBlock dismissBlock;

@property (strong, nonatomic) NSMutableSet* queuedMessages;

@end

@implementation WLToast

+ (instancetype)toast {
    static id instance = nil;
    if (instance == nil) {
        instance = [self loadFromNib];
    }
    return instance;
}

+ (void)showWithMessage:(NSString *)message {
    [self showWithMessage:message appearance:nil];
}

+ (void)showWithMessage:(NSString *)message appearance:(id<WLToastAppearance>)appearance {
    [self showWithMessage:message inViewController:nil appearance:appearance];
}

+ (void)showWithMessage:(NSString *)message inViewController:(UIViewController *)viewController {
    [self showWithMessage:message inViewController:viewController appearance:nil];
}

+ (void)showWithMessage:(NSString *)message inViewController:(UIViewController *)viewController appearance:(id<WLToastAppearance>)appearance {
    [[self toast] showWithMessage:message inViewController:viewController appearance:appearance];
}

- (void)showWithMessage:(NSString *)message inViewController:(UIViewController *)viewController appearance:(id<WLToastAppearance>)appearance {
    
    if (!message.nonempty || (self.superview != nil && [self.messageLabel.text isEqualToString:message])) {
        return;
    }
    
    if (!self.queuedMessages) {
        self.queuedMessages = [NSMutableSet setWithObject:message];
    } else {
        [self.queuedMessages addObject:message];
    }
    
    if (!viewController) {
        viewController = [UIViewController toastAppearanceViewController:self];
    }
    __weak UIViewController *weakViewController = viewController;
    if (!appearance) {
        appearance = [WLToastAppearance defaultAppearance];
    }
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(@"wl_toast_queue", ^(WLOperation *operation) {
        if (!weakViewController) {
            [weakSelf.queuedMessages removeObject:message];
            [operation finish];
            return;
        }
        UIView *view = weakViewController.view;
        UIView *referenceView = [weakViewController toastAppearanceReferenceView:weakSelf];
        
        if (!referenceView) {
            [weakSelf.queuedMessages removeObject:message];
            [operation finish];
            return;
        }
        
        [weakSelf applyAppearance:appearance];
        
        weakSelf.messageLabel.text = message;
        
        if (weakSelf.superview != view) {
            [weakSelf removeFromSuperview];
            weakSelf.translatesAutoresizingMaskIntoConstraints = NO;
            
            [view addSubview:weakSelf];
            [view addConstraint:[weakSelf constraintToItem:referenceView equal:NSLayoutAttributeWidth]];
            [view addConstraint:[weakSelf constraintToItem:referenceView equal:NSLayoutAttributeCenterX]];
            if (referenceView == view) {
                NSLayoutConstraint *topViewConstraint = [weakSelf constraintToItem:referenceView equal:NSLayoutAttributeTop];
                [view addConstraint:topViewConstraint];
                weakSelf.topViewConstraint = topViewConstraint;
                weakSelf.topMessageInset.constant = [UIApplication sharedApplication].statusBarHidden ? 6 : 26;
            } else {
                NSLayoutConstraint *topViewConstraint = [weakSelf constraintForAttrbute:NSLayoutAttributeTop toItem:referenceView equalToAttribute:NSLayoutAttributeBottom];
                [view addConstraint:topViewConstraint];
                weakSelf.topViewConstraint = topViewConstraint;
                weakSelf.topMessageInset.constant = 6;
            }
            
            [weakSelf layoutIfNeeded];
            weakSelf.alpha = 0.0f;
            [weakSelf layoutIfNeeded];
            [UIView performAnimated:YES animation:^{
                weakSelf.alpha = 1.0f;
            }];
        }
        
        weakSelf.dismissBlock = ^{
            [weakSelf.queuedMessages removeObject:message];
            [operation finish];
        };
        
        [weakSelf enqueueSelectorPerforming:@selector(dismiss) afterDelay:WLToastDismissalDelay];
    });
}

- (void)applyAppearance:(id<WLToastAppearance>)appearance {
    if ([appearance respondsToSelector:@selector(toastAppearanceShouldShowIcon:)]) {
        self.iconView.hidden = ![appearance toastAppearanceShouldShowIcon:self];
    }
    
    if ([appearance respondsToSelector:@selector(toastAppearanceBackgroundColor:)]) {
        self.backgroundColor = [appearance toastAppearanceBackgroundColor:self];
    }
    
    if ([appearance respondsToSelector:@selector(toastAppearanceTextColor:)]) {
        self.messageLabel.textColor = [appearance toastAppearanceTextColor:self];
    }
}

- (void)dismiss {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    __weak typeof(self)weakSelf = self;
    if (self.alpha > 0) {
        [UIView animateWithDuration:.25 animations:^{
            weakSelf.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [weakSelf removeFromSuperview];
            if (weakSelf.dismissBlock) weakSelf.dismissBlock();
        }];
    } else {
        [weakSelf removeFromSuperview];
        if (weakSelf.dismissBlock) weakSelf.dismissBlock();
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self dismiss];
}

@end

@implementation UIViewController (WLToast)

+ (UIViewController *)toastAppearanceViewController:(WLToast*)toast {
    UIViewController *visibleViewController = [UIWindow mainWindow].rootViewController;
    UIViewController *presentedViewController = visibleViewController.presentedViewController;
    while (presentedViewController) {
        if ([presentedViewController definesToastAppearance]) {
            visibleViewController = presentedViewController;
            presentedViewController = visibleViewController.presentedViewController;
        } else {
            presentedViewController = nil;
        }
    }
    if ([visibleViewController isKindOfClass:[UINavigationController class]]) {
        visibleViewController = [(UINavigationController*)visibleViewController topViewController];
    }
    return [visibleViewController toastAppearanceViewController:toast];
}

- (BOOL)definesToastAppearance {
    return YES;
}

- (UIViewController*)toastAppearanceViewController:(WLToast*)toast {
    return self;
}

- (UIView*)toastAppearanceReferenceView:(WLToast*)toast {
    UIView *referenceView = nil;
    if ([self respondsToSelector:@selector(navigationBar)]) {
        referenceView = [(id)self navigationBar];
    }
    if (!referenceView) {
        referenceView = self.view;
    }
    return referenceView;
}

@end

@interface UIAlertController (WLToast)

@end

@implementation UIAlertController (WLToast)

- (BOOL)definesToastAppearance {
    return NO;
}

@end

@implementation WLToast (DefinedToasts)

+ (void)showDownloadingMediaMessageForCandy:(Candy *)candy {
    if (candy.valid) {
        [self showWithMessage:[NSString stringWithFormat:(candy.isVideo ? @"downloading_video" : @"downloading_photo").ls, WLAlbumName]];
    } else {
        [self showWithMessage:@"downloading_media".ls];
    }
}

+ (void)showMessageForUnavailableWrap:(Wrap *)wrap {
    [self showWithMessage:[NSString stringWithFormat:@"formatted_wrap_unavailable".ls, wrap.name?:@""]];
}

@end
