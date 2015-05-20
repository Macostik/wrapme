//
//  WLToast.h
//  wrapLive
//
//  Created by Sergey Maximenko on 22.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSTimeInterval WLToastDismissalDelay = 4.0f;

@class WLToast;

@protocol WLToastAppearance <NSObject>

@optional

- (BOOL)toastAppearanceShouldShowIcon:(WLToast*)toast;

- (UIColor*)toastAppearanceBackgroundColor:(WLToast*)toast;

- (UIColor*)toastAppearanceTextColor:(WLToast*)toast;

@end

@interface WLToastAppearance : NSObject <WLToastAppearance>

+ (instancetype)defaultAppearance;

+ (instancetype)errorAppearance;

+ (instancetype)infoAppearance;

@property (nonatomic) BOOL shouldShowIcon;

@property (strong, nonatomic) UIColor* backgroundColor;

@property (strong, nonatomic) UIColor* textColor;

@end

@interface WLToast : UIView

+ (void)showWithMessage:(NSString *)message;

+ (void)showWithMessage:(NSString *)message appearance:(id<WLToastAppearance>)appearance;

+ (void)showWithMessage:(NSString *)message inViewController:(UIViewController*)viewController;

+ (void)showWithMessage:(NSString *)message inViewController:(UIViewController*)viewController appearance:(id<WLToastAppearance>)appearance;

@end

@interface UIViewController (WLToast) <WLToastAppearance>

+ (UIViewController*)toastAppearanceViewController:(WLToast*)toast;

- (UIViewController*)toastAppearanceViewController:(WLToast*)toast;

- (UIView*)toastAppearanceReferenceView:(WLToast*)toast;

@end

@interface WLToast (DefinedToasts)

+ (void)showPhotoDownloadingMessage;

+ (void)showMessageForUnavailableWrap:(WLWrap*)wrap;

@end
