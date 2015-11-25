//
//  WLWrapDataViewController.h
//  meWrap
//
//  Created by Ravenpod on 3/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"
#import "WLHistoryViewController.h"

@class  Candy, CandyInteractionController;

@interface WLCandyViewController : WLBaseViewController

@property (weak, nonatomic) Candy *candy;
@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) WLHistoryViewController *historyViewController;

@end
