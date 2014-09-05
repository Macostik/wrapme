//
//  WLWrapDataViewController.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLShakeViewController.h"

@class WLCandy;
@class WLWrap;
@class WLGroup;
@class WLGroupedSet;

@interface WLCandyViewController : WLShakeViewController

@property (strong, nonatomic) WLCandy *candy;

@property (strong, nonatomic) WLGroup *group;

@property (strong, nonatomic) WLGroupedSet *groups;

@end
