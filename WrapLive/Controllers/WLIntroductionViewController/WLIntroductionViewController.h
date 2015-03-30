//
//  WLIntroductionViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 3/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLIntroductionViewController;

@protocol WLIntroductionViewControllerDelegate <NSObject>

- (void)introductionViewControllerDidFinish:(WLIntroductionViewController*)controller;

@end

@interface WLIntroductionViewController : WLBaseViewController

@property (nonatomic, weak) id <WLIntroductionViewControllerDelegate> delegate;

@end
