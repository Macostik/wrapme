//
//  WLBaseViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 07.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLShakeViewController : UIViewController

- (UIViewController*)shakePresentedViewController;

- (void)didRecognizeShakeGesture;

@property (nonatomic) BOOL backSwipeGestureEnabled;

@end
