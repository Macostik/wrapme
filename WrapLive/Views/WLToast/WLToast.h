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

- (CGFloat)toastAppearanceHeight:(WLToast*)toast;

@end

@interface WLToast : UIView

+ (instancetype)toast;

+ (void)showWithMessage:(NSString*)message;

+ (void)showWithMessage:(NSString*)message appearance:(id <WLToastAppearance>)appearance;

- (void)showWithMessage:(NSString*)message;

- (void)showWithMessage:(NSString*)message appearance:(id <WLToastAppearance>)appearance;

@property (nonatomic) NSString* message;

@end

@interface UIViewController (WLToast) <WLToastAppearance>

@end
