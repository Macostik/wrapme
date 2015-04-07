//
//  WLToast.h
//  wrapLive
//
//  Created by Sergey Maximenko on 22.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSTimeInterval WLToastDismissalDelay = 8.0f;

@class WLToast;
@class WLToastViewController;

@protocol WLToastAppearance <NSObject>

@optional

- (BOOL)toastAppearanceShouldShowIcon:(WLToastViewController*)controller;

- (UIColor*)toastAppearanceBackgroundColor:(WLToastViewController*)controller;

- (UIColor*)toastAppearanceTextColor:(WLToastViewController*)controller;

- (UIViewContentMode)toastAppearanceContentMode:(WLToastViewController*)controller;

@end

@interface WLToastAppearance : NSObject <WLToastAppearance>

+ (instancetype)appearance;

@property (nonatomic) BOOL shouldShowIcon;

@property (strong, nonatomic) UIColor* backgroundColor;

@property (strong, nonatomic) UIColor* textColor;

@property (nonatomic) UIViewContentMode contentMode;

@end

@interface WLToast : NSObject

+ (void)showWithMessage:(NSString *)message;
+ (void)showWithMessage:(NSString *)message appearance:(id<WLToastAppearance>)appearance;

@end

@interface WLToastWindow : UIWindow

+ (WLToastWindow *)sharedWindow;
- (void)setViewControllerAsRoot;
- (id)toastAsRootViewController;
- (void)dismissAfterDelay;
- (void)dismiss;

@end

@interface WLToastViewController : UIViewController

@property (weak, nonatomic, readonly) UIView *contentView;

- (void)setMessage:(NSString *)message withAppearance:(id<WLToastAppearance>)appearance;
- (void)dismissWithComplition:(void (^)(BOOL finished))completion;

@end

@interface UIViewController (WLToast) <WLToastAppearance>

@end

@interface WLToast (DefinedToasts)

+ (void)showPhotoDownloadingMessage;

@end
