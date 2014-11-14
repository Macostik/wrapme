//
//  WLBaseViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 07.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBaseViewController.h"

@interface WLShakeViewController : WLBaseViewController

- (UIViewController*)shakePresentedViewController;

- (BOOL)didRecognizeShakeGesture;

@end
