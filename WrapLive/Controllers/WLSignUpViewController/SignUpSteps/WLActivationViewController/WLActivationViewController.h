//
//  WLActivationViewController.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLAuthorization;

@interface WLActivationViewController : WLBaseViewController

- (instancetype)initWithAuthorization:(WLAuthorization*)authorization;

@end
