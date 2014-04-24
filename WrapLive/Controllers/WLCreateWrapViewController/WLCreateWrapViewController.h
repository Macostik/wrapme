//
//  WLCreateWrapViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLShakeViewController.h"

@class WLWrap;

typedef NS_ENUM(NSUInteger, WLWrapTransition) {
	WLWrapTransitionWithoutAnimation,
	WLWrapTransitionFromBottom,
	WLWrapTransitionFromRight
};

@interface WLCreateWrapViewController : WLShakeViewController

@property (strong, nonatomic) WLWrap* wrap;

- (void)presentInViewController:(UIViewController*)controller transition:(WLWrapTransition)transition;
- (void)dismiss:(WLWrapTransition)transition;
- (void)dismiss;

@end
