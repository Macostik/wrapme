//
//  WLWrapDataViewController.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLCandy;
@class WLWrap;

@interface WLWrapDataViewController : UIViewController

@property (strong, nonatomic) WLCandy *candy;
@property (strong, nonatomic) WLWrap *wrap;

@end
