//
//  WLToast.h
//  wrapLive
//
//  Created by Sergey Maximenko on 22.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLToast;

@protocol WLToastAppearance <NSObject>

@optional

- (CGFloat)toastAppearanceHeight:(WLToast*)toast;

- (BOOL)toastAppearanceShouldShowIcon:(WLToast*)toast;

- (UIColor*)toastAppearanceBackgroundColor:(WLToast*)toast;

- (UIColor*)toastAppearanceTextColor:(WLToast*)toast;

- (UIViewContentMode)toastAppearanceContentMode:(WLToast*)toast;

- (CGFloat)toastAppearanceStartY:(WLToast*)toast;

- (CGFloat)toastAppearanceEndY:(WLToast*)toast;

@end

@interface WLToastAppearance : NSObject <WLToastAppearance>

+ (instancetype)appearance;

@property (nonatomic) CGFloat height;

@property (nonatomic) CGFloat startY;

@property (nonatomic) CGFloat endY;

@property (nonatomic) BOOL shouldShowIcon;

@property (strong, nonatomic) UIColor* backgroundColor;

@property (strong, nonatomic) UIColor* textColor;

@property (nonatomic) UIViewContentMode contentMode;

@end

@interface WLToast : UIView

+ (instancetype)toast;

+ (void)showWithMessage:(NSString*)message;

+ (void)showWithMessage:(NSString*)message appearance:(id <WLToastAppearance>)appearance;

+ (void)showWithMessage:(NSString*)message appearance:(id <WLToastAppearance>)appearance inView:(UIView*)view;

- (void)showWithMessage:(NSString*)message;

- (void)showWithMessage:(NSString*)message appearance:(id <WLToastAppearance>)appearance;

- (void)showWithMessage:(NSString*)message appearance:(id <WLToastAppearance>)appearance inView:(UIView*)view;

@property (nonatomic) NSString* message;

@end

@interface UIViewController (WLToast) <WLToastAppearance>

@end
