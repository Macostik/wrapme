//
//  WLActivationViewController.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAuthorizationSceneViewController.h"

@class WLAuthorization;

@interface WLActivationViewController : WLAuthorizationSceneViewController

@property (strong, nonatomic) WLAuthorization *authorization;

@end
