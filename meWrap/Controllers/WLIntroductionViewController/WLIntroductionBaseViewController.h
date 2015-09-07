//
//  WLIntroductionBaseViewController.h
//  meWrap
//
//  Created by Ravenpod on 3/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLIntroductionBaseViewController;

@protocol WLIntroductionBaseViewControllerDelegate <NSObject>

- (void)introductionBaseViewControllerDidContinueIntroduction:(WLIntroductionBaseViewController*)controller;

- (void)introductionBaseViewControllerDidFinishIntroduction:(WLIntroductionBaseViewController*)controller;

@end

@interface WLIntroductionBaseViewController : UIViewController

@property (nonatomic, weak) id <WLIntroductionBaseViewControllerDelegate> delegate;

@end
