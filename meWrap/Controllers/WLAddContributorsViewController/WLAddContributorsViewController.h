//
//  WLContributorsViewController.h
//  meWrap
//
//  Created by Ravenpod on 25.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@interface WLAddContributorsViewController : WLBaseViewController

@property (weak, nonatomic) Wrap *wrap;

@property (assign, nonatomic) BOOL isBroadcasting;

@property (strong, nonatomic) BooleanBlock completionHandler;

@end
