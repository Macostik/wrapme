//
//  WLWrapDataViewController.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLSwipeViewController.h"

@class WLCandy;
@class WLWrap;
@class WLGroup;

@interface WLCandyViewController : WLSwipeViewController

@property (weak, nonatomic) UIViewController *backViewController;

@property (strong, nonatomic) WLCandy *candy;

@property (strong, nonatomic) WLGroup *group;

- (void)setCandy:(WLCandy *)candy group:(WLGroup*)group;

@end
