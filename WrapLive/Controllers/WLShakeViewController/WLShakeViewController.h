//
//  WLBaseViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 07.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WLWrapTransition) {
	WLWrapTransitionWithoutAnimation,
	WLWrapTransitionFromBottom,
	WLWrapTransitionFromRight,
	WLWrapTransitionFromLeft
};

@interface WLShakeViewController : UIViewController

@property (assign, nonatomic) BOOL isShowPlaceholder;
@property (nonatomic) BOOL backSwipeGestureEnabled;
@property (nonatomic) BOOL notPresentShakeViewController;
@property (nonatomic, strong) UIView* translucentView;
@property (strong, nonatomic) UIImageView *noContentPlaceholder;
@property (strong, nonatomic) UIImageView *titleNoContentPlaceholder;

- (void)presentInViewController:(UIViewController*)controller transition:(WLWrapTransition)transition completion:(void (^)(void))completion;

- (void)presentInViewController:(UIViewController*)controller transition:(WLWrapTransition)transition;

- (void)dismiss:(WLWrapTransition)transition completion:(void (^)(void))completion;

- (void)dismiss:(WLWrapTransition)transition;

- (void)dismiss;

- (UIViewController*)shakePresentedViewController;

- (BOOL)didRecognizeShakeGesture;

- (void)setTranslucent;

- (void)showPlaceholder;

@end
