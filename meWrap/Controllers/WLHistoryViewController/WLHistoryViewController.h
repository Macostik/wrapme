//
//  WLHistoryViewController.h
//  meWrap
//
//  Created by Ravenpod on 5/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSwipeViewController.h"

@class LayoutPrioritizer, History, HistoryItem, Wrap, Candy, CandyEnlargingPresenter;

@interface WLHistoryViewController : WLSwipeViewController

@property (weak, nonatomic) Candy *candy;

@property (strong, nonatomic) HistoryItem *historyItem;

@property (nonatomic) BOOL showCommentViewController;

@property (strong, nonatomic) CandyEnlargingPresenter *presenter;

@property (copy, nonatomic) Block commentPressed;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *commentButtonPrioritizer;


- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)hideSecondaryViews:(BOOL)hide;

- (void)showCommentView;

- (void)applyScaleToCandyViewController:(BOOL)apply;

@end
