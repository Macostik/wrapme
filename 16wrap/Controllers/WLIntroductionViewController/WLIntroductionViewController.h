//
//  WLIntroductionViewController.h
//  moji
//
//  Created by Ravenpod on 3/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSwipeViewController.h"

@class WLIntroductionViewController;

@protocol WLIntroductionViewControllerDelegate <NSObject>

- (void)introductionViewControllerDidFinish:(WLIntroductionViewController*)controller;

@end

@interface WLIntroductionViewController : WLSwipeViewController

@property (nonatomic, weak) id <WLIntroductionViewControllerDelegate> delegate;

@end
