//
//  WLHistoryViewController.h
//  meWrap
//
//  Created by Ravenpod on 5/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSwipeViewController.h"
#import "WLPresentingImageView.h"
#import "WLHistory.h"

@class Wrap, Candy, LayoutPrioritizer;

@interface WLHistoryViewController : WLSwipeViewController

@property (strong, nonatomic) WLHistory *history;

@property (weak, nonatomic) Wrap *wrap;

@property (weak, nonatomic) Candy *candy;

@property (nonatomic) BOOL showCommentViewController;

@property (strong, nonatomic) WLPresentingImageView *presentingImageView;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *commentButtonPrioritizer;

- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)showCommentView;

- (void)applyScaleToCandyViewController:(BOOL)apply;

@end
