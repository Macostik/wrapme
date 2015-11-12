//
//  WLFollowingViewController.h
//  meWrap
//
//  Created by Sergey Maximenko on 8/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@interface WLFollowingViewController : WLBaseViewController

@property (weak, nonatomic) Wrap *wrap;

@property (strong, nonatomic) WLBlock actionBlock;

+ (void)followWrapIfNeeded:(Wrap *)wrap performAction:(WLBlock)action;

@end
