//
//  WLFollowingViewController.h
//  meWrap
//
//  Created by Sergey Maximenko on 8/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class Wrap;

@interface WLFollowingViewController : WLBaseViewController

@property (weak, nonatomic) Wrap *wrap;

@property (strong, nonatomic) Block actionBlock;

+ (void)followWrapIfNeeded:(Wrap *)wrap performAction:(Block)action;

@end
