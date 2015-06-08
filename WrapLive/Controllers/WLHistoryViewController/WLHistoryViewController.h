//
//  WLHistoryViewController.h
//  wrapLive
//
//  Created by Sergey Maximenko on 5/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSwipeViewController.h"
#import "WLPresentingImageView.h"

@interface WLHistoryViewController : WLSwipeViewController

@property (strong, nonatomic) WLHistory *history;

@property (strong, nonatomic) WLHistoryItem *historyItem;

@property (weak, nonatomic) WLWrap* wrap;

@property (weak, nonatomic) WLCandy* candy;

@property (nonatomic) BOOL showCommentViewController;

@property (strong, nonatomic) WLPresentingImageView *presentingImageView;

- (IBAction)hideBars;

- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)showCommentView;

@end
