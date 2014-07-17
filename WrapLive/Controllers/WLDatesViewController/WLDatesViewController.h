//
//  WLDatesViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLShakeViewController.h"
#import "WLGroupedSet.h"

@class WLWrap;

@interface WLDatesViewController : WLShakeViewController

@property (strong, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) WLGroupedSet* dates;

@end
