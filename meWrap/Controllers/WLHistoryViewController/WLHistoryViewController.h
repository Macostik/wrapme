//
//  WLHistoryViewController.h
//  meWrap
//
//  Created by Ravenpod on 5/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSwipeViewController.h"
#import "WLPresentingImageView.h"

@class LayoutPrioritizer, History, Wrap;

@interface WLHistoryViewController : WLSwipeViewController

@property (strong, nonatomic) History *history;

@property (weak, nonatomic) Wrap *wrap;

@property (weak, nonatomic) Candy *candy;

@property (nonatomic) BOOL showCommentViewController;

@property (strong, nonatomic) WLPresentingImageView *presentingImageView;

@property (copy, nonatomic) Block commentPressed;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *commentButtonPrioritizer;


- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)hideSecondaryViews:(BOOL)hide;

- (void)showCommentView;

- (void)applyScaleToCandyViewController:(BOOL)apply;

@end
