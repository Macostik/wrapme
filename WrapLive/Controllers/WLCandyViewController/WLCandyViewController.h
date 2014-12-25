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
@class WLHistoryItem;
@class WLHistory;

@interface WLCandyViewController : WLShakeViewController

@property (strong, nonatomic) WLCandy *candy;

@property (nonatomic) BOOL showCommentInputKeyboard;

@end
