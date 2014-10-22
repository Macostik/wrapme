//
//  WLBaseViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 07.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBaseViewController.h"

@interface WLShakeViewController : WLBaseViewController

@property (assign, nonatomic) BOOL isShowPlaceholder;
@property (nonatomic) BOOL backSwipeGestureEnabled;
@property (nonatomic, strong) UIView* translucentView;
@property (strong, nonatomic) UIImageView *noContentPlaceholder;
@property (strong, nonatomic) UIImageView *titleNoContentPlaceholder;

- (UIViewController*)shakePresentedViewController;

- (BOOL)didRecognizeShakeGesture;

- (void)setTranslucent;

- (void)showPlaceholder;

@end
