//
//  WLWrapDataViewController.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLShakeViewController.h"

@interface WLCandyViewController : WLShakeViewController

@property (weak, nonatomic) WLCandy *candy;

@property (nonatomic) BOOL showCommentInputKeyboard;

@property (nonatomic) BOOL showCommentViewController;

- (IBAction)hideBars;

- (IBAction)setBarsHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)showCommentView;

@end
