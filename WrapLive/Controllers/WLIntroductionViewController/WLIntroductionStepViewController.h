//
//  WLIntroductionStepViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 3/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLIntroductionStepViewController;

@protocol WLIntroductionStepViewControllerDelegate <NSObject>

- (void)introductionStepViewControllerDidFinish:(WLIntroductionStepViewController*)controller;

- (void)introductionStepViewControllerDidContinue:(WLIntroductionStepViewController*)controller;

@end

@interface WLIntroductionStepViewController : UIViewController

@property (nonatomic, weak) id <WLIntroductionStepViewControllerDelegate> delegate;

@end
