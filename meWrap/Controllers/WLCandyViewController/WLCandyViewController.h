//
//  WLWrapDataViewController.h
//  meWrap
//
//  Created by Ravenpod on 3/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class  Candy, SlideInteractiveTransition, ImageView, HistoryViewController;

@interface WLCandyViewController : WLBaseViewController

@property (weak, nonatomic) Candy *candy;
@property (weak, nonatomic) IBOutlet ImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) HistoryViewController *historyViewController;

@end
