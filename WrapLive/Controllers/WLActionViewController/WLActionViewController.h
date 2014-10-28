//
//  WLActionViewController.h
//  WrapLive
//
//  Created by Yura Granchenko on 10/27/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditViewController.h"
#import "WLButton.h"



@class WLContentView;

@interface WLActionViewController : UIViewController

+ (void)addEditWrapViewControllerWithWrap:(WLWrap *)wrap toParentViewController:(UIViewController *)viewController;
+ (void)addCandyViewControllerWithCandy:(WLCandy *)candy toParentViewController:(UIViewController *)viewController;

@end
