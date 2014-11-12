//
//  WLActionViewController.h
//  WrapLive
//
//  Created by Yura Granchenko on 10/27/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditViewController.h"
#import "WLStillPictureViewController.h"
#import "WLButton.h"

@interface WLActionViewController : UIViewController

+ (id)addViewControllerByClass:(Class)class toParentViewController:(UIViewController *)viewController;
+ (id)addViewControllerByClass:(Class)class withEntry:(id)entry toParentViewController:(UIViewController *)viewController;

- (void)dismiss;
- (void)removeAnimateViewsFromSuperView;

@end

@interface UIViewController (WLActionViewController)

- (void)setEntry:(id)entry;

@end

